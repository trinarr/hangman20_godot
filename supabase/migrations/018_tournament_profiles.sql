-- Apply after 017. Bounded public profile sampling independent of ranking.
begin;
set local lock_timeout = '5s';

-- An expression index avoids an extra per-player column. The random pivot walks
-- a stable shuffled ring, then wraps once; each range returns at most 50 rows.
create index if not exists players_tournament_sample_idx
  on leaderboard_private.players ((md5(player_id::text)), player_id) where stars > 0;

create or replace function public.tournament_profiles(p_language text default 'en')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  pivot text := pg_catalog.md5(pg_catalog.random()::text);
  board_language text := case when lower(split_part(replace(coalesce(p_language, 'en'), '_', '-'), '-', 1)) = 'ru' then 'ru' else 'en' end;
  result jsonb;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  with ahead as materialized (
    select p.player_id, p.user_id
    from leaderboard_private.players p
    where p.stars > 0 and p.user_id <> player and md5(p.player_id::text) >= pivot
    order by md5(p.player_id::text), p.player_id limit 50
  ), behind as materialized (
    select p.player_id, p.user_id
    from leaderboard_private.players p
    where p.stars > 0 and p.user_id <> player and md5(p.player_id::text) < pivot
    order by md5(p.player_id::text), p.player_id
    limit (50 - (select count(*) from ahead))
  ), chosen as (
    select * from ahead union all select * from behind
  )
  select jsonb_build_object('ok', true, 'protocol_version', 1, 'profiles',
    coalesce(jsonb_agg(jsonb_build_object(
      'player_id', c.player_id::text,
      'nickname', left(coalesce(profile.nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || c.player_id::text), 24),
      'character_id', coalesce(profile.character_id, 1), 'frame_id', coalesce(profile.frame_id, 4),
      'is_me', false, 'is_filler', false
    ) order by c.player_id), '[]'::jsonb)) into result
  from chosen c left join leaderboard_private.profiles profile on profile.user_id = c.user_id;
  return result;
end;
$$;
revoke all on function public.tournament_profiles(text) from public, anon;
grant execute on function public.tournament_profiles(text) to authenticated;

-- An expression index avoids an extra per-player column. The random pivot walks
-- a stable shuffled ring, then wraps once; each range returns at most 50 rows.
create index if not exists players_tournament_sample_idx
  on leaderboard_dev_private.players ((md5(player_id::text)), player_id) where stars > 0;

create or replace function public.tournament_profiles_dev(p_language text default 'en')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  pivot text := pg_catalog.md5(pg_catalog.random()::text);
  board_language text := case when lower(split_part(replace(coalesce(p_language, 'en'), '_', '-'), '-', 1)) = 'ru' then 'ru' else 'en' end;
  result jsonb;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  with ahead as materialized (
    select p.player_id, p.user_id
    from leaderboard_dev_private.players p
    where p.stars > 0 and p.user_id <> player and md5(p.player_id::text) >= pivot
    order by md5(p.player_id::text), p.player_id limit 50
  ), behind as materialized (
    select p.player_id, p.user_id
    from leaderboard_dev_private.players p
    where p.stars > 0 and p.user_id <> player and md5(p.player_id::text) < pivot
    order by md5(p.player_id::text), p.player_id
    limit (50 - (select count(*) from ahead))
  ), chosen as (
    select * from ahead union all select * from behind
  )
  select jsonb_build_object('ok', true, 'protocol_version', 1, 'profiles',
    coalesce(jsonb_agg(jsonb_build_object(
      'player_id', c.player_id::text,
      'nickname', left(coalesce(profile.nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || c.player_id::text), 24),
      'character_id', coalesce(profile.character_id, 1), 'frame_id', coalesce(profile.frame_id, 4),
      'is_me', false, 'is_filler', false
    ) order by c.player_id), '[]'::jsonb)) into result
  from chosen c left join leaderboard_dev_private.profiles profile on profile.user_id = c.user_id;
  return result;
end;
$$;
revoke all on function public.tournament_profiles_dev(text) from public, anon;
grant execute on function public.tournament_profiles_dev(text) to authenticated;

notify pgrst, 'reload schema';
commit;
