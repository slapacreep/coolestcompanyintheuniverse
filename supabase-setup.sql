-- Coolest Company practice lobby v1 — run once in Supabase SQL Editor.
-- Requires Authentication > Providers > Anonymous Sign-Ins = enabled.
create extension if not exists pgcrypto;
create table if not exists public.cc_rooms (
  id uuid primary key default gen_random_uuid(),
  invite uuid unique not null default gen_random_uuid(),
  host_id uuid not null references auth.users(id),
  company text not null default 'Custom Team',
  logo text,
  colour text not null default '#e2283a',
  rider text not null default 'snow',
  status text not null default 'waiting' check(status in ('waiting','playing','finished')),
  starts_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.cc_players (
  room_id uuid not null references public.cc_rooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  player_colour text not null,
  joined_at timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  score bigint not null default 0 check(score>=0),
  primary key(room_id,user_id)
);
create index if not exists cc_players_user_id_idx on public.cc_players(user_id);
alter table public.cc_rooms enable row level security;
alter table public.cc_players enable row level security;
-- Tables cannot be directly mutated from the browser. All writes pass controlled functions.
revoke all on public.cc_rooms, public.cc_players from anon, authenticated;
grant select on public.cc_rooms, public.cc_players to authenticated;
create or replace function public.cc_is_member(p_room uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.cc_players where room_id=p_room and user_id=(select auth.uid()));
$$;
revoke all on function public.cc_is_member(uuid) from public, anon;
grant execute on function public.cc_is_member(uuid) to authenticated;
drop policy if exists cc_rooms_members_read on public.cc_rooms;
create policy cc_rooms_members_read on public.cc_rooms for select to authenticated
using (public.cc_is_member(id));
drop policy if exists cc_players_members_read on public.cc_players;
create policy cc_players_members_read on public.cc_players for select to authenticated
using (public.cc_is_member(room_id));

create or replace function public.cc_create_room(p_name text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare r public.cc_rooms; uid uuid := auth.uid(); nm text := left(btrim(coalesce(p_name,'')),40);
begin
 if uid is null then raise exception 'Sign in first'; end if;
 if length(nm)<1 then raise exception 'Enter your name'; end if;
 insert into public.cc_rooms(host_id) values(uid) returning * into r;
 insert into public.cc_players(room_id,user_id,display_name,player_colour)
 values(r.id,uid,nm,'#ff4747');
 return jsonb_build_object('room_id',r.id,'invite',r.invite);
end $$;
create or replace function public.cc_join_room(p_invite uuid,p_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare rid uuid; uid uuid := auth.uid(); nm text := left(btrim(coalesce(p_name,'')),40); cnt integer; clr text;
begin
 if uid is null then raise exception 'Sign in first'; end if;
 if length(nm)<1 then raise exception 'Enter your name'; end if;
 select id into rid from public.cc_rooms where invite=p_invite and status='waiting' for update;
 if rid is null then raise exception 'This room does not exist or has already started'; end if;
 if exists(select 1 from public.cc_players where room_id=rid and user_id=uid) then
  update public.cc_players set display_name=nm,last_seen=now() where room_id=rid and user_id=uid;
  return rid;
 end if;
 select count(*) into cnt from public.cc_players where room_id=rid;
 if cnt>=4 then raise exception 'Room is full (4 players)'; end if;
 clr := (array['#ff4747','#3485ff','#31d16f','#ffd93d'])[cnt+1];
 insert into public.cc_players(room_id,user_id,display_name,player_colour) values(rid,uid,nm,clr);
 return rid;
end $$;
create or replace function public.cc_update_team(p_room uuid,p_company text,p_colour text,p_logo text,p_rider text)
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
 if not exists(select 1 from public.cc_rooms where id=p_room and host_id=uid and status='waiting') then
  raise exception 'Only the room host may change the team before starting'; end if;
 if length(btrim(coalesce(p_company,''))) not between 1 and 60 then raise exception 'Invalid company name'; end if;
 if p_colour !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Invalid colour'; end if;
 if length(coalesce(p_logo,'')) > 65000 then raise exception 'Logo is too large'; end if;
 if p_logo is not null and p_logo !~ '^data:image/(png|jpeg|webp);base64,' then raise exception 'Invalid image'; end if;
 if p_rider not in ('snow','santa','penguin','bear','elf','reindeer') then
   -- Older game builds have different rider IDs; allow safe identifiers only.
   if p_rider !~ '^[a-z0-9_-]{1,24}$' then raise exception 'Invalid character'; end if;
 end if;
 update public.cc_rooms set company=btrim(p_company),colour=p_colour,logo=p_logo,rider=p_rider where id=p_room;
end $$;
create or replace function public.cc_start_room(p_room uuid)
returns timestamptz language plpgsql security definer set search_path = '' as $$
declare moment timestamptz;
begin
 moment := now()+interval '5 seconds';
 update public.cc_rooms set status='playing',starts_at=moment
 where id=p_room and host_id=auth.uid() and status='waiting';
 if not found then raise exception 'Only the host can start a waiting room'; end if;
 return moment;
end $$;
create or replace function public.cc_heartbeat(p_room uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
 update public.cc_players set last_seen=now() where room_id=p_room and user_id=auth.uid();
end $$;
create or replace function public.cc_leave_room(p_room uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if exists(select 1 from public.cc_rooms where id=p_room and host_id=auth.uid()) then
  delete from public.cc_rooms where id=p_room;
 else delete from public.cc_players where room_id=p_room and user_id=auth.uid(); end if;
end $$;
-- Prototype score reporting, NOT tamper-resistant. Do not use for prizes or payments.
create or replace function public.cc_report_score(p_room uuid,p_score bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
 if p_score<0 or p_score>100000000 then raise exception 'Invalid score'; end if;
 update public.cc_players set score=greatest(score,p_score) where room_id=p_room and user_id=auth.uid()
 and exists(select 1 from public.cc_rooms where id=p_room and status='playing');
end $$;
revoke all on function public.cc_create_room(text),public.cc_join_room(uuid,text),public.cc_update_team(uuid,text,text,text,text),public.cc_start_room(uuid),public.cc_heartbeat(uuid),public.cc_leave_room(uuid),public.cc_report_score(uuid,bigint) from public,anon;
grant execute on function public.cc_create_room(text),public.cc_join_room(uuid,text),public.cc_update_team(uuid,text,text,text,text),public.cc_start_room(uuid),public.cc_heartbeat(uuid),public.cc_leave_room(uuid),public.cc_report_score(uuid,bigint) to authenticated;
-- Allow realtime member-scoped SELECT events. Safe to re-run.
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='cc_rooms') then
  alter publication supabase_realtime add table public.cc_rooms;
 end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='cc_players') then
  alter publication supabase_realtime add table public.cc_players;
 end if;
end $$;
