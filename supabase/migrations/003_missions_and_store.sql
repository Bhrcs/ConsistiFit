create table public.shop_items (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text not null,
  category text not null,
  coin_price int not null check(coin_price > 0),
  active boolean not null default true,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table public.inventory (
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.shop_items(id),
  quantity int not null default 1 check(quantity >= 0),
  updated_at timestamptz not null default now(),
  primary key(user_id,item_id)
);

alter table public.shop_items enable row level security;
alter table public.inventory enable row level security;
create policy shop_items_read on public.shop_items for select to anon,authenticated using(active=true);
create policy inventory_self_read on public.inventory for select to authenticated using((select auth.uid())=user_id);
grant select on public.shop_items to anon,authenticated;
grant select on public.inventory to authenticated;

create or replace function public.complete_daily_mission(p_code text)
returns table(rp_awarded int,xp_awarded int,coins_awarded int,new_rank_points int,new_rank text)
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid := auth.uid();
  v_mission public.missions;
  v_completion_id uuid;
  v_old_rank text;
  v_new_rank text;
  v_steps int;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_code not in ('steps','mobility','checkin','recovery') then raise exception 'mission is not client-completable'; end if;

  select * into v_mission from public.missions where code=p_code and active=true and cadence='daily';
  if not found then raise exception 'mission not found'; end if;

  if p_code='steps' then
    select steps into v_steps from public.health_daily_snapshots where user_id=v_uid and day=current_date;
    if coalesce(v_steps,0) < 8000 then raise exception 'step target not met'; end if;
  end if;

  insert into public.mission_completions(user_id,mission_id,completed_on)
  values(v_uid,v_mission.id,current_date)
  on conflict(user_id,mission_id,completed_on) do nothing
  returning id into v_completion_id;

  if v_completion_id is null then
    select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
    rp_awarded:=0; xp_awarded:=0; coins_awarded:=0; new_rank:=v_new_rank; return next; return;
  end if;

  select current_rank into v_old_rank from public.profiles where user_id=v_uid;
  update public.profiles
  set rank_points=greatest(0,rank_points+v_mission.rp_reward),
      account_xp=account_xp+v_mission.xp_reward,
      account_level=greatest(account_level,1+floor((account_xp+v_mission.xp_reward)/1000.0)::int),
      coins=coins+v_mission.coin_reward,
      updated_at=now()
  where user_id=v_uid;
  update public.profiles set current_rank=public.rank_from_rp(rank_points) where user_id=v_uid;

  insert into public.reward_ledger(user_id,source_type,source_id,earned_on,rp_delta,xp_delta,coin_delta)
  values(v_uid,'mission',v_completion_id,current_date,v_mission.rp_reward,v_mission.xp_reward,v_mission.coin_reward);

  select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
  if v_old_rank is distinct from v_new_rank then
    insert into public.rank_history(user_id,previous_rank,new_rank,rank_points)
    values(v_uid,v_old_rank,v_new_rank,new_rank_points);
  end if;
  insert into public.activity_feed(user_id,event_type,payload)
  values(v_uid,'mission_completed',jsonb_build_object('mission',p_code,'rp',v_mission.rp_reward));

  rp_awarded:=v_mission.rp_reward;
  xp_awarded:=v_mission.xp_reward;
  coins_awarded:=v_mission.coin_reward;
  new_rank:=v_new_rank;
  return next;
end;
$$;

create or replace function public.purchase_shop_item(p_item_code text)
returns table(item_code text,quantity int,coins_remaining int)
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid := auth.uid();
  v_item public.shop_items;
  v_coins int;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_item from public.shop_items where code=p_item_code and active=true;
  if not found then raise exception 'item not found'; end if;
  if v_item.category='rank' or (v_item.payload ? 'rp') then raise exception 'rank points cannot be purchased'; end if;

  select coins into v_coins from public.profiles where user_id=v_uid for update;
  if v_coins is null or v_coins < v_item.coin_price then raise exception 'not enough coins'; end if;

  update public.profiles set coins=coins-v_item.coin_price,updated_at=now() where user_id=v_uid;
  insert into public.inventory(user_id,item_id,quantity)
  values(v_uid,v_item.id,1)
  on conflict(user_id,item_id) do update set quantity=public.inventory.quantity+1,updated_at=now();

  select i.quantity,p.coins into quantity,coins_remaining
  from public.inventory i join public.profiles p on p.user_id=i.user_id
  where i.user_id=v_uid and i.item_id=v_item.id;
  item_code:=v_item.code;
  return next;
end;
$$;

revoke execute on function public.complete_daily_mission(text) from public,anon;
grant execute on function public.complete_daily_mission(text) to authenticated;
revoke execute on function public.purchase_shop_item(text) from public,anon;
grant execute on function public.purchase_shop_item(text) to authenticated;

insert into public.shop_items(code,name,description,category,coin_price,payload) values
('xp_booster','XP Booster','Boosts permanent account XP on eligible future progression events. Never grants RP.','booster',450,'{"xp_multiplier":1.25,"duration_hours":24}'),
('streak_shield','Streak Shield','Protects one eligible missed consistency day. Does not prevent weekly rank adjustment.','utility',350,'{"charges":1}'),
('graphite_theme','Graphite Theme','Profile and app cosmetic theme.','cosmetic',700,'{"theme":"graphite"}'),
('lime_finish','Lime Finish','Workout completion cosmetic effect.','cosmetic',500,'{"effect":"lime_finish"}'),
('founder_title','Founding Athlete','Profile title for early ConsistiFit supporters.','cosmetic',900,'{"title":"Founding Athlete"}')
on conflict(code) do update set name=excluded.name,description=excluded.description,category=excluded.category,coin_price=excluded.coin_price,payload=excluded.payload;
