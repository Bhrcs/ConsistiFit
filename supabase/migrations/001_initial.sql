create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.friendship_status as enum ('pending','accepted','blocked');
create type public.workout_status as enum ('planned','in_progress','completed','skipped');

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Athlete',
  account_xp integer not null default 0 check(account_xp >= 0),
  account_level integer not null default 1 check(account_level >= 1),
  coins integer not null default 0 check(coins >= 0),
  rank_points integer not null default 0 check(rank_points >= 0),
  current_rank text not null default 'Iron III',
  streak_days integer not null default 0,
  longest_streak integer not null default 0,
  consistency_percent numeric(5,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.programs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  goal text not null,
  experience text not null,
  equipment text not null,
  days_per_week int not null check(days_per_week between 2 and 7),
  session_minutes int not null check(session_minutes between 20 and 120),
  weeks int not null default 8 check(weeks between 1 and 52),
  active boolean not null default true,
  current_week int not null default 1 check(current_week >= 1),
  created_at timestamptz not null default now()
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  movement_family text not null,
  equipment text[] not null default '{}',
  muscles text[] not null default '{}',
  replacement_group text,
  instructions text,
  created_at timestamptz not null default now()
);

create table public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete cascade,
  name text not null,
  sequence_no int not null,
  estimated_minutes int not null default 45
);

create table public.template_exercises (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.workout_templates(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id),
  sequence_no int not null,
  sets int not null check(sets between 1 and 12),
  rep_min int,
  rep_max int,
  rest_seconds int not null default 90 check(rest_seconds between 0 and 600)
);

create table public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  template_id uuid references public.workout_templates(id),
  workout_name text not null default 'Workout',
  scheduled_for date not null default current_date,
  status public.workout_status not null default 'planned',
  started_at timestamptz,
  completed_at timestamptz,
  difficulty text,
  reward_claimed boolean not null default false,
  duration_seconds int not null default 0 check(duration_seconds >= 0),
  total_volume numeric not null default 0 check(total_volume >= 0),
  created_at timestamptz not null default now()
);

create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  workout_log_id uuid not null references public.workout_logs(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id),
  set_no int not null check(set_no between 1 and 30),
  weight numeric not null default 0 check(weight >= 0),
  reps int not null default 0 check(reps >= 0),
  rpe numeric check(rpe is null or (rpe >= 1 and rpe <= 10)),
  completed boolean not null default false,
  created_at timestamptz not null default now(),
  unique(workout_log_id, exercise_id, set_no)
);

create table public.missions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  cadence text not null,
  rp_reward int not null default 0,
  xp_reward int not null default 0,
  coin_reward int not null default 0,
  active boolean not null default true
);

create table public.mission_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mission_id uuid not null references public.missions(id),
  completed_on date not null default current_date,
  unique(user_id,mission_id,completed_on)
);

create table public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null,
  source_id uuid,
  earned_on date not null default current_date,
  rp_delta int not null default 0,
  xp_delta int not null default 0,
  coin_delta int not null default 0,
  created_at timestamptz not null default now()
);
create unique index reward_source_once on public.reward_ledger(user_id,source_type,source_id) where source_id is not null;
create unique index one_ranked_workout_reward_per_day on public.reward_ledger(user_id,earned_on) where source_type='workout';

create table public.rank_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  previous_rank text,
  new_rank text not null,
  rank_points int not null,
  created_at timestamptz not null default now()
);

create table public.personal_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_id uuid references public.exercises(id),
  record_type text not null,
  value numeric not null,
  unit text not null,
  achieved_at timestamptz not null default now()
);

create table public.health_daily_snapshots (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  steps int,
  active_calories numeric,
  distance_meters numeric,
  sleep_minutes int,
  source text,
  synced_at timestamptz not null default now(),
  primary key(user_id,day)
);

create table public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  workout_reminders boolean not null default true,
  mission_reminders boolean not null default true,
  rank_updates boolean not null default true,
  quiet_start time,
  quiet_end time,
  updated_at timestamptz not null default now()
);

create table public.weekly_consistency (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  planned_training_days int not null,
  completed_training_days int not null,
  adherence_percent numeric(5,2) not null,
  rp_adjustment int not null,
  processed_at timestamptz not null default now(),
  unique(user_id, week_start)
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique(requester_id,addressee_id),
  check(requester_id <> addressee_id)
);

create table public.squads (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.squad_members (
  squad_id uuid not null references public.squads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key(squad_id,user_id)
);

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  squad_id uuid references public.squads(id) on delete cascade,
  name text not null,
  metric text not null,
  target numeric not null check(target > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now(),
  check(ends_at > starts_at)
);

create table public.challenge_members (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  progress numeric not null default 0 check(progress >= 0),
  joined_at timestamptz not null default now(),
  primary key(challenge_id,user_id)
);

create table public.activity_feed (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  insert into public.profiles(user_id,display_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name','Athlete'))
  on conflict(user_id) do nothing;
  insert into public.notification_preferences(user_id)
  values(new.id)
  on conflict(user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure private.handle_new_user();

create or replace function public.rank_from_rp(p_rp integer)
returns text
language sql
immutable
set search_path=''
as $$
select case
  when p_rp>=6000 then 'Grandmaster'
  when p_rp>=4500 then 'Master'
  when p_rp>=3600 then 'Diamond I'
  when p_rp>=3000 then 'Diamond II'
  when p_rp>=2600 then 'Diamond III'
  when p_rp>=2300 then 'Platinum I'
  when p_rp>=2100 then 'Platinum II'
  when p_rp>=1900 then 'Platinum III'
  when p_rp>=1750 then 'Gold I'
  when p_rp>=1550 then 'Gold II'
  when p_rp>=1350 then 'Gold III'
  when p_rp>=1100 then 'Silver I'
  when p_rp>=900 then 'Silver II'
  when p_rp>=700 then 'Silver III'
  when p_rp>=500 then 'Bronze I'
  when p_rp>=350 then 'Bronze II'
  when p_rp>=200 then 'Bronze III'
  when p_rp>=100 then 'Iron I'
  when p_rp>=50 then 'Iron II'
  else 'Iron III'
end;
$$;

create or replace function public.complete_workout_and_reward(p_workout_log_id uuid, p_difficulty text)
returns table(rp_awarded int,xp_awarded int,coins_awarded int,new_rank_points int,new_rank text)
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid := auth.uid();
  v_log public.workout_logs;
  v_old_rank text;
  v_new_rank text;
  v_last_reward_day date;
  v_new_streak int;
  v_already_rewarded boolean;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_difficulty not in ('tooEasy','good','hard','tooHard') then raise exception 'invalid difficulty'; end if;

  select * into v_log
  from public.workout_logs
  where id=p_workout_log_id and user_id=v_uid
  for update;
  if not found then raise exception 'workout not found'; end if;
  if v_log.reward_claimed then raise exception 'rewards already claimed'; end if;

  select exists(
    select 1 from public.reward_ledger
    where user_id=v_uid and source_type='workout' and earned_on=v_log.scheduled_for
  ) into v_already_rewarded;

  update public.workout_logs
  set status='completed', completed_at=coalesce(completed_at,now()), difficulty=p_difficulty, reward_claimed=true
  where id=p_workout_log_id;

  if v_already_rewarded then
    select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
    rp_awarded:=0; xp_awarded:=0; coins_awarded:=0; new_rank:=v_new_rank; return next; return;
  end if;

  insert into public.profiles(user_id) values(v_uid) on conflict(user_id) do nothing;
  select current_rank into v_old_rank from public.profiles where user_id=v_uid;
  select max(earned_on) into v_last_reward_day
  from public.reward_ledger
  where user_id=v_uid and source_type='workout' and earned_on < v_log.scheduled_for;

  select case
    when v_last_reward_day = v_log.scheduled_for - 1 then streak_days + 1
    else 1
  end into v_new_streak
  from public.profiles where user_id=v_uid;

  update public.profiles
  set rank_points=rank_points+35,
      account_xp=account_xp+240,
      account_level=greatest(account_level,1+floor((account_xp+240)/1000.0)::int),
      coins=coins+85,
      streak_days=v_new_streak,
      longest_streak=greatest(longest_streak,v_new_streak),
      updated_at=now()
  where user_id=v_uid;

  update public.profiles
  set current_rank=public.rank_from_rp(rank_points)
  where user_id=v_uid;

  insert into public.reward_ledger(user_id,source_type,source_id,earned_on,rp_delta,xp_delta,coin_delta)
  values(v_uid,'workout',p_workout_log_id,v_log.scheduled_for,35,240,85);

  select rank_points,current_rank into new_rank_points,v_new_rank
  from public.profiles where user_id=v_uid;

  if v_old_rank is distinct from v_new_rank then
    insert into public.rank_history(user_id,previous_rank,new_rank,rank_points)
    values(v_uid,v_old_rank,v_new_rank,new_rank_points);
  end if;

  insert into public.activity_feed(user_id,event_type,payload)
  values(v_uid,'workout_completed',jsonb_build_object('workout_log_id',p_workout_log_id,'workout_name',v_log.workout_name,'rp',35));

  rp_awarded:=35; xp_awarded:=240; coins_awarded:=85; new_rank:=v_new_rank; return next;
end;
$$;

create or replace function public.apply_weekly_consistency_adjustment(p_week_start date)
returns table(rp_adjustment int, adherence_percent numeric, new_rank_points int, new_rank text)
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid := auth.uid();
  v_planned int;
  v_completed int;
  v_adherence numeric(5,2);
  v_adjustment int;
  v_record_id uuid;
  v_existing public.weekly_consistency;
  v_old_rank text;
  v_new_rank text;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if extract(isodow from p_week_start) <> 1 then raise exception 'week_start must be Monday'; end if;
  if p_week_start > current_date - 7 then raise exception 'week is not complete'; end if;

  select * into v_existing from public.weekly_consistency
  where user_id=v_uid and week_start=p_week_start;
  if found then
    select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
    rp_adjustment:=v_existing.rp_adjustment;
    adherence_percent:=v_existing.adherence_percent;
    new_rank:=v_new_rank;
    return next;
    return;
  end if;

  select coalesce((select days_per_week from public.programs where user_id=v_uid and active=true order by created_at desc limit 1),3)
  into v_planned;

  select count(distinct earned_on)::int into v_completed
  from public.reward_ledger
  where user_id=v_uid and source_type='workout'
    and earned_on between p_week_start and p_week_start + 6;

  v_adherence := least(100, round((v_completed::numeric / greatest(v_planned,1)) * 100, 2));
  v_adjustment := case
    when v_adherence >= 100 then 50
    when v_adherence >= 80 then 0
    when v_adherence >= 60 then -25
    else -50
  end;

  select current_rank into v_old_rank from public.profiles where user_id=v_uid;

  insert into public.weekly_consistency(user_id,week_start,planned_training_days,completed_training_days,adherence_percent,rp_adjustment)
  values(v_uid,p_week_start,v_planned,v_completed,v_adherence,v_adjustment)
  returning id into v_record_id;

  update public.profiles
  set rank_points=greatest(0,rank_points+v_adjustment),
      consistency_percent=v_adherence,
      updated_at=now()
  where user_id=v_uid;
  update public.profiles set current_rank=public.rank_from_rp(rank_points) where user_id=v_uid;

  insert into public.reward_ledger(user_id,source_type,source_id,earned_on,rp_delta,xp_delta,coin_delta)
  values(v_uid,'weekly_adjustment',v_record_id,p_week_start+6,v_adjustment,case when v_adherence>=100 then 150 else 0 end,case when v_adherence>=100 then 100 else 0 end);

  if v_adherence >= 100 then
    update public.profiles set account_xp=account_xp+150,coins=coins+100 where user_id=v_uid;
    insert into public.activity_feed(user_id,event_type,payload)
    values(v_uid,'perfect_week',jsonb_build_object('week_start',p_week_start,'rp',50));
  end if;

  select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
  if v_old_rank is distinct from v_new_rank then
    insert into public.rank_history(user_id,previous_rank,new_rank,rank_points)
    values(v_uid,v_old_rank,v_new_rank,new_rank_points);
  end if;

  rp_adjustment:=v_adjustment; adherence_percent:=v_adherence; new_rank:=v_new_rank; return next;
end;
$$;

create or replace function public.search_profiles(p_query text)
returns table(user_id uuid,display_name text,current_rank text,streak_days int)
language plpgsql
security definer
set search_path=''
as $$
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if length(trim(p_query)) < 2 then return; end if;
  return query
  select p.user_id,p.display_name,p.current_rank,p.streak_days
  from public.profiles p
  where p.user_id <> auth.uid()
    and p.display_name ilike '%' || trim(p_query) || '%'
  order by p.display_name
  limit 20;
end;
$$;

alter table public.profiles enable row level security;
alter table public.programs enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_templates enable row level security;
alter table public.template_exercises enable row level security;
alter table public.workout_logs enable row level security;
alter table public.workout_sets enable row level security;
alter table public.missions enable row level security;
alter table public.mission_completions enable row level security;
alter table public.reward_ledger enable row level security;
alter table public.rank_history enable row level security;
alter table public.personal_records enable row level security;
alter table public.health_daily_snapshots enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.weekly_consistency enable row level security;
alter table public.friendships enable row level security;
alter table public.squads enable row level security;
alter table public.squad_members enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_members enable row level security;
alter table public.activity_feed enable row level security;

create policy profiles_self_select on public.profiles for select to authenticated using((select auth.uid())=user_id);
create policy profiles_self_update on public.profiles for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy programs_self on public.programs for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy exercises_read on public.exercises for select to anon,authenticated using(true);
create policy workout_templates_self on public.workout_templates for all to authenticated
using(exists(select 1 from public.programs p where p.id=program_id and p.user_id=(select auth.uid())))
with check(exists(select 1 from public.programs p where p.id=program_id and p.user_id=(select auth.uid())));
create policy template_exercises_self on public.template_exercises for all to authenticated
using(exists(select 1 from public.workout_templates wt join public.programs p on p.id=wt.program_id where wt.id=template_id and p.user_id=(select auth.uid())))
with check(exists(select 1 from public.workout_templates wt join public.programs p on p.id=wt.program_id where wt.id=template_id and p.user_id=(select auth.uid())));
create policy workout_logs_self on public.workout_logs for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy workout_sets_self on public.workout_sets for all to authenticated
using(exists(select 1 from public.workout_logs w where w.id=workout_log_id and w.user_id=(select auth.uid())))
with check(exists(select 1 from public.workout_logs w where w.id=workout_log_id and w.user_id=(select auth.uid())));
create policy missions_read on public.missions for select to anon,authenticated using(active=true);
create policy mission_completions_self on public.mission_completions for select to authenticated using((select auth.uid())=user_id);
create policy reward_ledger_self on public.reward_ledger for select to authenticated using((select auth.uid())=user_id);
create policy rank_history_self on public.rank_history for select to authenticated using((select auth.uid())=user_id);
create policy prs_self on public.personal_records for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy health_self on public.health_daily_snapshots for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy notifications_self on public.notification_preferences for all to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create policy weekly_consistency_self on public.weekly_consistency for select to authenticated using((select auth.uid())=user_id);
create policy friendships_visible on public.friendships for select to authenticated using(requester_id=(select auth.uid()) or addressee_id=(select auth.uid()));
create policy friendships_request on public.friendships for insert to authenticated with check(requester_id=(select auth.uid()) and status='pending');
create policy friendships_update on public.friendships for update to authenticated using(requester_id=(select auth.uid()) or addressee_id=(select auth.uid())) with check(requester_id=(select auth.uid()) or addressee_id=(select auth.uid()));
create policy friendships_delete on public.friendships for delete to authenticated using(requester_id=(select auth.uid()) or addressee_id=(select auth.uid()));
create policy squads_visible on public.squads for select to authenticated using(true);
create policy squads_create on public.squads for insert to authenticated with check(owner_id=(select auth.uid()));
create policy squads_owner_update on public.squads for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy squads_owner_delete on public.squads for delete to authenticated using(owner_id=(select auth.uid()));
create policy squad_members_visible on public.squad_members for select to authenticated using(true);
create policy squad_members_self_join on public.squad_members for insert to authenticated with check(user_id=(select auth.uid()));
create policy squad_members_leave on public.squad_members for delete to authenticated using(user_id=(select auth.uid()) or exists(select 1 from public.squads s where s.id=squad_id and s.owner_id=(select auth.uid())));
create policy challenges_visible on public.challenges for select to authenticated using(true);
create policy challenges_create on public.challenges for insert to authenticated with check(creator_id=(select auth.uid()));
create policy challenges_owner_update on public.challenges for update to authenticated using(creator_id=(select auth.uid())) with check(creator_id=(select auth.uid()));
create policy challenges_owner_delete on public.challenges for delete to authenticated using(creator_id=(select auth.uid()));
create policy challenge_members_visible on public.challenge_members for select to authenticated using(true);
create policy challenge_members_join on public.challenge_members for insert to authenticated with check(user_id=(select auth.uid()));
create policy challenge_members_leave on public.challenge_members for delete to authenticated using(user_id=(select auth.uid()));
create policy activity_feed_friends on public.activity_feed for select to authenticated using(
  user_id=(select auth.uid()) or exists(
    select 1 from public.friendships f
    where f.status='accepted' and ((f.requester_id=(select auth.uid()) and f.addressee_id=activity_feed.user_id) or (f.addressee_id=(select auth.uid()) and f.requester_id=activity_feed.user_id))
  )
);

grant usage on schema public to anon, authenticated;
grant select on public.exercises, public.missions to anon, authenticated;
grant select on public.profiles to authenticated;
grant update(display_name) on public.profiles to authenticated;
grant select,insert,update,delete on public.programs to authenticated;
grant select,insert,update,delete on public.workout_templates, public.template_exercises to authenticated;
grant select on public.workout_logs to authenticated;
grant insert(user_id,template_id,workout_name,scheduled_for,status,started_at,duration_seconds,total_volume) on public.workout_logs to authenticated;
grant update(status,started_at,duration_seconds,total_volume) on public.workout_logs to authenticated;
grant delete on public.workout_logs to authenticated;
grant select,insert,update,delete on public.workout_sets to authenticated;
grant select on public.mission_completions, public.reward_ledger, public.rank_history, public.weekly_consistency to authenticated;
grant select,insert,update,delete on public.personal_records, public.health_daily_snapshots to authenticated;
grant select,insert on public.notification_preferences to authenticated;
grant update(workout_reminders,mission_reminders,rank_updates,quiet_start,quiet_end,updated_at) on public.notification_preferences to authenticated;
grant select,insert,delete on public.friendships to authenticated;
grant update(status) on public.friendships to authenticated;
grant select,insert,delete on public.squads to authenticated;
grant update(name,description) on public.squads to authenticated;
grant select,insert,delete on public.squad_members to authenticated;
grant select,insert,delete on public.challenges to authenticated;
grant update(name,metric,target,starts_at,ends_at) on public.challenges to authenticated;
grant select,insert,delete on public.challenge_members to authenticated;
grant select on public.activity_feed to authenticated;

revoke execute on function public.complete_workout_and_reward(uuid,text) from public,anon;
grant execute on function public.complete_workout_and_reward(uuid,text) to authenticated;
revoke execute on function public.apply_weekly_consistency_adjustment(date) from public,anon;
grant execute on function public.apply_weekly_consistency_adjustment(date) to authenticated;
revoke execute on function public.search_profiles(text) from public,anon;
grant execute on function public.search_profiles(text) to authenticated;

insert into public.missions(code,name,cadence,rp_reward,xp_reward,coin_reward) values
('scheduled_workout','Scheduled workout','daily',30,220,85),
('recovery','Planned recovery','daily',15,60,20),
('steps','Step target','daily',10,40,0),
('mobility','Mobility reset','daily',10,30,0),
('checkin','Training check-in','daily',5,20,0),
('perfect_week','Perfect planned week','weekly',50,150,100)
on conflict(code) do nothing;
