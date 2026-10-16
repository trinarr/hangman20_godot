-- Apply after 004. No production quiz data is changed. Safe to rerun.
begin;
create schema if not exists leaderboard_private;
revoke all on schema leaderboard_private from public, anon, authenticated;
create table if not exists leaderboard_private.players (
  player_id bigint generated always as identity primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  stars bigint not null check (stars between 0 and 2000000000),
  reached_at timestamptz not null default clock_timestamp()
);
create index if not exists players_ranking_idx on leaderboard_private.players
  (stars desc, reached_at asc, player_id asc);
alter table leaderboard_private.players enable row level security;
revoke all on all tables in schema leaderboard_private from public, anon, authenticated;
revoke all on all sequences in schema leaderboard_private from public, anon, authenticated;

-- Optional score submission plus a bounded snapshot, in one request.
-- p_stars=null is read-only and does not create a participant.
create or replace function public.leaderboard_sync(p_stars bigint default null, p_include_top boolean default true)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  result jsonb;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_include_top is null or (p_stars is not null and (p_stars < 0 or p_stars > 2000000000)) then
    raise exception 'Invalid leaderboard payload' using errcode = '22023';
  end if;
  if p_stars is not null then
    insert into leaderboard_private.players as existing(user_id, stars) values (player, p_stars)
    on conflict (user_id) do update
      set stars = excluded.stars, reached_at = clock_timestamp()
      where excluded.stars > existing.stars;
  end if;
  -- All reads (top and own position) share one statement snapshot.
  with mine as (
    select m.player_id, m.stars, m.reached_at,
      1 + (select count(*) from leaderboard_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))) as rank
    from leaderboard_private.players m where m.user_id = player
  ), top_players as (
    select p.player_id, p.stars, p.reached_at, p.user_id = player as is_me
    from leaderboard_private.players p where p_include_top
    order by p.stars desc, p.reached_at, p.player_id limit 100
  ), ranked_top as (
    select player_id, stars, is_me,
      row_number() over (order by stars desc, reached_at, player_id) as rank
    from top_players
  )
  select jsonb_build_object('ok', true, 'me',
    (select jsonb_build_object('player_id', player_id::text, 'stars', stars, 'rank', rank) from mine))
    || case when p_include_top then jsonb_build_object('top',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id::text, 'stars', stars, 'rank', rank, 'is_me', is_me) order by rank)
        from ranked_top), '[]'::jsonb)) else '{}'::jsonb end
    into result;
  return result;
end;
$$;
revoke all on function public.leaderboard_sync(bigint, boolean) from public, anon;
grant execute on function public.leaderboard_sync(bigint, boolean) to authenticated;

create schema if not exists leaderboard_dev_private;
revoke all on schema leaderboard_dev_private from public, anon, authenticated;
create table if not exists leaderboard_dev_private.players (
  player_id bigint generated always as identity primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  stars bigint not null check (stars between 0 and 2000000000),
  reached_at timestamptz not null default clock_timestamp()
);
create index if not exists players_ranking_idx on leaderboard_dev_private.players
  (stars desc, reached_at asc, player_id asc);
alter table leaderboard_dev_private.players enable row level security;
revoke all on all tables in schema leaderboard_dev_private from public, anon, authenticated;
revoke all on all sequences in schema leaderboard_dev_private from public, anon, authenticated;

-- Optional score submission plus a bounded snapshot, in one request.
-- p_stars=null is read-only and does not create a participant.
create or replace function public.leaderboard_sync_dev(p_stars bigint default null, p_include_top boolean default true)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  result jsonb;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_include_top is null or (p_stars is not null and (p_stars < 0 or p_stars > 2000000000)) then
    raise exception 'Invalid leaderboard payload' using errcode = '22023';
  end if;
  if p_stars is not null then
    insert into leaderboard_dev_private.players as existing(user_id, stars) values (player, p_stars)
    on conflict (user_id) do update
      set stars = excluded.stars, reached_at = clock_timestamp()
      where excluded.stars > existing.stars;
  end if;
  -- All reads (top and own position) share one statement snapshot.
  with mine as (
    select m.player_id, m.stars, m.reached_at,
      1 + (select count(*) from leaderboard_dev_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))) as rank
    from leaderboard_dev_private.players m where m.user_id = player
  ), top_players as (
    select p.player_id, p.stars, p.reached_at, p.user_id = player as is_me
    from leaderboard_dev_private.players p where p_include_top
    order by p.stars desc, p.reached_at, p.player_id limit 100
  ), ranked_top as (
    select player_id, stars, is_me,
      row_number() over (order by stars desc, reached_at, player_id) as rank
    from top_players
  )
  select jsonb_build_object('ok', true, 'me',
    (select jsonb_build_object('player_id', player_id::text, 'stars', stars, 'rank', rank) from mine))
    || case when p_include_top then jsonb_build_object('top',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id::text, 'stars', stars, 'rank', rank, 'is_me', is_me) order by rank)
        from ranked_top), '[]'::jsonb)) else '{}'::jsonb end
    into result;
  return result;
end;
$$;
revoke all on function public.leaderboard_sync_dev(bigint, boolean) from public, anon;
grant execute on function public.leaderboard_sync_dev(bigint, boolean) to authenticated;

commit;
