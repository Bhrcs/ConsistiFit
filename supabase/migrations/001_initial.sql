create extension if not exists pgcrypto;

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
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.programs (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, name text not null, goal text not null, experience text not null, equipment text not null, days_per_week int not null check(days_per_week between 2 and 7), session_minutes int not null, weeks int not null default 8, active boolean not null default true, current_week int not null default 1, created_at timestamptz not null default now());
create table public.exercises (id uuid primary key default gen_random_uuid(), name text unique not null, movement_family text not null, equipment text[] not null default '{}', muscles text[] not null default '{}', replacement_group text, instructions text, created_at timestamptz not null default now());
create table public.workout_templates (id uuid primary key default gen_random_uuid(), program_id uuid not null references public.programs(id) on delete cascade, name text not null, sequence_no int not null, estimated_minutes int not null default 45);
create table public.template_exercises (id uuid primary key default gen_random_uuid(), template_id uuid not null references public.workout_templates(id) on delete cascade, exercise_id uuid not null references public.exercises(id), sequence_no int not null, sets int not null, rep_min int, rep_max int, rest_seconds int not null default 90);
create table public.workout_logs (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, template_id uuid references public.workout_templates(id), scheduled_for date not null default current_date, status public.workout_status not null default 'planned', started_at timestamptz, completed_at timestamptz, difficulty text, reward_claimed boolean not null default false, duration_seconds int not null default 0, total_volume numeric not null default 0, created_at timestamptz not null default now());
create table public.workout_sets (id uuid primary key default gen_random_uuid(), workout_log_id uuid not null references public.workout_logs(id) on delete cascade, exercise_id uuid not null references public.exercises(id), set_no int not null, weight numeric not null default 0, reps int not null default 0, rpe numeric, completed boolean not null default false, created_at timestamptz not null default now());
create table public.missions (id uuid primary key default gen_random_uuid(), code text unique not null, name text not null, cadence text not null, rp_reward int not null default 0, xp_reward int not null default 0, coin_reward int not null default 0, active boolean not null default true);
create table public.mission_completions (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, mission_id uuid not null references public.missions(id), completed_on date not null default current_date, unique(user_id,mission_id,completed_on));
create table public.reward_ledger (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, source_type text not null, source_id uuid, rp_delta int not null default 0, xp_delta int not null default 0, coin_delta int not null default 0, created_at timestamptz not null default now());
create unique index reward_source_once on public.reward_ledger(user_id,source_type,source_id) where source_id is not null;
create table public.rank_history (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, previous_rank text, new_rank text not null, rank_points int not null, created_at timestamptz not null default now());
create table public.personal_records (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, exercise_id uuid references public.exercises(id), record_type text not null, value numeric not null, unit text not null, achieved_at timestamptz not null default now());
create table public.health_daily_snapshots (user_id uuid not null references auth.users(id) on delete cascade, day date not null, steps int, active_calories numeric, distance_meters numeric, sleep_minutes int, source text, synced_at timestamptz not null default now(), primary key(user_id,day));
create table public.notification_preferences (user_id uuid primary key references auth.users(id) on delete cascade, workout_reminders boolean not null default true, mission_reminders boolean not null default true, rank_updates boolean not null default true, quiet_start time, quiet_end time, updated_at timestamptz not null default now());

create table public.friendships (id uuid primary key default gen_random_uuid(), requester_id uuid not null references auth.users(id) on delete cascade default auth.uid(), addressee_id uuid not null references auth.users(id) on delete cascade, status public.friendship_status not null default 'pending', created_at timestamptz not null default now(), unique(requester_id,addressee_id), check(requester_id <> addressee_id));
create table public.squads (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(), name text not null, description text, created_at timestamptz not null default now());
create table public.squad_members (squad_id uuid not null references public.squads(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, role text not null default 'member', joined_at timestamptz not null default now(), primary key(squad_id,user_id));
create table public.challenges (id uuid primary key default gen_random_uuid(), creator_id uuid not null references auth.users(id) on delete cascade default auth.uid(), squad_id uuid references public.squads(id) on delete cascade, name text not null, metric text not null, target numeric not null, starts_at timestamptz not null, ends_at timestamptz not null, created_at timestamptz not null default now());
create table public.challenge_members (challenge_id uuid not null references public.challenges(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, progress numeric not null default 0, joined_at timestamptz not null default now(), primary key(challenge_id,user_id));
create table public.activity_feed (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, event_type text not null, payload jsonb not null default '{}', created_at timestamptz not null default now());

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(user_id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name','Athlete')) on conflict(user_id) do nothing; insert into public.notification_preferences(user_id) values(new.id) on conflict(user_id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.rank_from_rp(p_rp integer) returns text language sql immutable as $$
select case when p_rp>=6000 then 'Grandmaster' when p_rp>=4500 then 'Master' when p_rp>=3600 then 'Diamond I' when p_rp>=3000 then 'Diamond II' when p_rp>=2600 then 'Diamond III' when p_rp>=2300 then 'Platinum I' when p_rp>=2100 then 'Platinum II' when p_rp>=1900 then 'Platinum III' when p_rp>=1750 then 'Gold I' when p_rp>=1550 then 'Gold II' when p_rp>=1350 then 'Gold III' when p_rp>=1100 then 'Silver I' when p_rp>=900 then 'Silver II' when p_rp>=700 then 'Silver III' when p_rp>=500 then 'Bronze I' when p_rp>=350 then 'Bronze II' when p_rp>=200 then 'Bronze III' when p_rp>=100 then 'Iron I' when p_rp>=50 then 'Iron II' else 'Iron III' end; $$;

create or replace function public.complete_workout_and_reward(p_workout_log_id uuid, p_difficulty text)
returns table(rp_awarded int,xp_awarded int,coins_awarded int,new_rank_points int,new_rank text) language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_log public.workout_logs; v_old_rank text; v_new_rank text; begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  select * into v_log from public.workout_logs where id=p_workout_log_id and user_id=v_uid for update;
  if not found then raise exception 'workout not found'; end if;
  if v_log.reward_claimed then raise exception 'rewards already claimed'; end if;
  if p_difficulty not in ('tooEasy','good','hard','tooHard') then raise exception 'invalid difficulty'; end if;
  update public.workout_logs set status='completed',completed_at=coalesce(completed_at,now()),difficulty=p_difficulty,reward_claimed=true where id=p_workout_log_id;
  insert into public.profiles(user_id) values(v_uid) on conflict(user_id) do nothing;
  select current_rank into v_old_rank from public.profiles where user_id=v_uid;
  update public.profiles set rank_points=rank_points+35,account_xp=account_xp+240,account_level=greatest(account_level,1+floor((account_xp+240)/1000.0)::int),coins=coins+85,streak_days=streak_days+1,longest_streak=greatest(longest_streak,streak_days+1),updated_at=now() where user_id=v_uid;
  update public.profiles set current_rank=public.rank_from_rp(rank_points) where user_id=v_uid;
  insert into public.reward_ledger(user_id,source_type,source_id,rp_delta,xp_delta,coin_delta) values(v_uid,'workout',p_workout_log_id,35,240,85);
  select rank_points,current_rank into new_rank_points,v_new_rank from public.profiles where user_id=v_uid;
  if v_old_rank is distinct from v_new_rank then insert into public.rank_history(user_id,previous_rank,new_rank,rank_points) values(v_uid,v_old_rank,v_new_rank,new_rank_points); end if;
  insert into public.activity_feed(user_id,event_type,payload) values(v_uid,'workout_completed',jsonb_build_object('workout_log_id',p_workout_log_id,'rp',35));
  rp_awarded:=35;xp_awarded:=240;coins_awarded:=85;new_rank:=v_new_rank;return next;
end; $$;

alter table public.profiles enable row level security; alter table public.programs enable row level security; alter table public.workout_logs enable row level security; alter table public.workout_sets enable row level security; alter table public.mission_completions enable row level security; alter table public.reward_ledger enable row level security; alter table public.rank_history enable row level security; alter table public.personal_records enable row level security; alter table public.health_daily_snapshots enable row level security; alter table public.notification_preferences enable row level security; alter table public.friendships enable row level security; alter table public.squads enable row level security; alter table public.squad_members enable row level security; alter table public.challenges enable row level security; alter table public.challenge_members enable row level security; alter table public.activity_feed enable row level security;

create policy profiles_self on public.profiles for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy programs_self on public.programs for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy workout_logs_self on public.workout_logs for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy workout_sets_self on public.workout_sets for all using(exists(select 1 from public.workout_logs w where w.id=workout_log_id and w.user_id=auth.uid())) with check(exists(select 1 from public.workout_logs w where w.id=workout_log_id and w.user_id=auth.uid()));
create policy mission_completions_self on public.mission_completions for select using(user_id=auth.uid());
create policy reward_ledger_self on public.reward_ledger for select using(user_id=auth.uid());
create policy rank_history_self on public.rank_history for select using(user_id=auth.uid());
create policy prs_self on public.personal_records for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy health_self on public.health_daily_snapshots for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy notifications_self on public.notification_preferences for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy friendships_visible on public.friendships for select using(requester_id=auth.uid() or addressee_id=auth.uid());
create policy friendships_request on public.friendships for insert with check(requester_id=auth.uid());
create policy friendships_update on public.friendships for update using(requester_id=auth.uid() or addressee_id=auth.uid());
create policy squads_visible on public.squads for select using(auth.uid() is not null); create policy squads_create on public.squads for insert with check(owner_id=auth.uid()); create policy squads_owner_update on public.squads for update using(owner_id=auth.uid());
create policy squad_members_visible on public.squad_members for select using(auth.uid() is not null); create policy squad_members_self_join on public.squad_members for insert with check(user_id=auth.uid());
create policy challenges_visible on public.challenges for select using(auth.uid() is not null); create policy challenges_create on public.challenges for insert with check(creator_id=auth.uid());
create policy challenge_members_visible on public.challenge_members for select using(auth.uid() is not null); create policy challenge_members_join on public.challenge_members for insert with check(user_id=auth.uid()); create policy challenge_members_self_update on public.challenge_members for update using(user_id=auth.uid());
create policy activity_feed_friends on public.activity_feed for select using(user_id=auth.uid() or exists(select 1 from public.friendships f where f.status='accepted' and ((f.requester_id=auth.uid() and f.addressee_id=activity_feed.user_id) or (f.addressee_id=auth.uid() and f.requester_id=activity_feed.user_id))));

insert into public.missions(code,name,cadence,rp_reward,xp_reward,coin_reward) values
('scheduled_workout','Scheduled workout','daily',30,220,85),('recovery','Planned recovery','daily',15,60,20),('steps','Step target','daily',10,40,0),('mobility','Mobility reset','daily',10,30,0),('checkin','Training check-in','daily',5,20,0),('perfect_week','Perfect planned week','weekly',50,150,100)
on conflict(code) do nothing;
