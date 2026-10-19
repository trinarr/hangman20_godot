-- Apply after 010. Optional profile fields preserve the four-argument client API.
begin;
create table if not exists leaderboard_private.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 18 and nickname = btrim(nickname) and nickname !~ '[[:cntrl:]]'),
  character_id integer not null check (character_id between 1 and 2),
  frame_id integer not null check (frame_id between 1 and 5),
  updated_at timestamptz not null default clock_timestamp()
);
alter table leaderboard_private.profiles enable row level security;
revoke all on leaderboard_private.profiles from public, anon, authenticated;
drop function if exists public.leaderboard_sync(bigint, boolean, text, boolean);
create or replace function public.leaderboard_sync(p_stars bigint default null, p_include_top boolean default true, p_language text default 'en', p_seed_fillers boolean default false, p_nickname text default null, p_character_id integer default null, p_frame_id integer default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  result jsonb;
  board_language text := case when lower(split_part(replace(coalesce(p_language, 'en'), '_', '-'), '-', 1)) = 'ru' then 'ru' else 'en' end;
  cis_percentage integer := case when board_language = 'ru' then 60 else 20 end;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_include_top is null or p_seed_fillers is null or (p_stars is not null and (p_stars < 0 or p_stars > 2000000000)) then
    raise exception 'Invalid leaderboard payload' using errcode = '22023';
  end if;
  -- A profile can exist without a ranked score. Legacy clients never erase it.
  if p_nickname is not null or p_character_id is not null or p_frame_id is not null then
    if p_nickname is null or p_character_id is null or p_frame_id is null
      or char_length(p_nickname) not between 2 and 18 or p_nickname <> btrim(p_nickname)
      or p_nickname ~ '[[:cntrl:]]' or p_character_id not between 1 and 2 or p_frame_id not between 1 and 5 then
      raise exception 'Invalid player profile' using errcode = '22023';
    end if;
    insert into leaderboard_private.profiles as existing(user_id, nickname, character_id, frame_id)
      values (player, p_nickname, p_character_id, p_frame_id)
    on conflict (user_id) do update set nickname = excluded.nickname,
      character_id = excluded.character_id, frame_id = excluded.frame_id, updated_at = clock_timestamp()
      where (existing.nickname, existing.character_id, existing.frame_id)
        is distinct from (excluded.nickname, excluded.character_id, excluded.frame_id);
  end if;
  if p_stars is not null and p_stars > 0 then
    insert into leaderboard_private.players as existing(user_id, stars) values (player, p_stars)
    on conflict (user_id) do update
      set stars = excluded.stars, reached_at = clock_timestamp()
      where excluded.stars > existing.stars;
  end if;
  -- All reads (top and own position) share one statement snapshot.
  with population as (select count(*) as total from leaderboard_private.players where stars > 0), mine as (
    select m.player_id, m.stars, m.reached_at, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id,
      1 + (select count(*) from leaderboard_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))) as rank
    from leaderboard_private.players m left join leaderboard_private.profiles profile on profile.user_id = m.user_id where m.user_id = player and m.stars > 0
  ), top_players as (
    select p.player_id, p.stars, p.reached_at, p.user_id = player as is_me, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id
    from leaderboard_private.players p left join leaderboard_private.profiles profile on profile.user_id = p.user_id where p_include_top and p.stars > 0
    order by p.stars desc, p.reached_at, p.player_id limit 100
  ), ranked_top as (
    select player_id, stars, is_me, nickname, character_id, frame_id,
      row_number() over (order by stars desc, reached_at, player_id) as rank
    from top_players
  ), scored_fillers as (
    select f.*, row_number() over (partition by f.pool
      order by md5('pick:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text), f.slot) as pool_rank
    from leaderboard_private.fillers f
    where p_include_top and p_seed_fillers and (select total from population) < 100
  ), chosen_fillers as (
    select f.* from scored_fillers f
    where f.pool_rank <= case when f.pool='cis' then cis_percentage else 100-cis_percentage end
  ), filler_values as (
    select 'filler:' || f.pool || ':' || lpad(f.slot::text, 3, '0') as player_id,
      f.nickname,
      30 + (('x' || substr(md5('stars:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text),1,8))::bit(32)::bigint % 71) as stars
    from chosen_fillers f
  ), filler_rows as (
    select f.*, 1 + (('x' || substr(md5(player_id),1,8))::bit(32)::bigint % 2)::integer as character_id,
      1 + (('x' || substr(md5('frame:' || player_id),1,8))::bit(32)::bigint % 5)::integer as frame_id, false as is_me, true as is_filler,
      row_number() over (order by stars desc, player_id) as rank from filler_values f
  ), display_top as (
    select player_id::text as player_id,
      coalesce(nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || player_id::text) as nickname, character_id, frame_id,
      stars, is_me, false as is_filler, rank from ranked_top
  )
  select jsonb_build_object('ok', true, 'protocol_version', 2, 'owner_id', player::text, 'language', board_language, 'total_players', (select total from population), 'me',
    (select jsonb_build_object('player_id', player_id::text,
      'nickname', coalesce(nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || player_id::text), 'character_id', character_id, 'frame_id', frame_id,
      'is_filler', false, 'stars', stars,
      'rank', case when rank <= 100 then rank else null end,
      'top_percent', case when rank > 100 then
        ceil(100::numeric * rank / (select total from population))::integer else null end) from mine))
    || case when p_include_top then jsonb_build_object('top',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id, 'nickname', nickname, 'character_id', character_id, 'frame_id', frame_id, 'stars', stars, 'rank', rank, 'is_me', is_me, 'is_filler', is_filler) order by rank)
        from display_top), '[]'::jsonb)) else '{}'::jsonb end
    || case when p_include_top and p_seed_fillers then jsonb_build_object('fillers',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id, 'nickname', nickname, 'character_id', character_id, 'frame_id', frame_id, 'stars', stars, 'rank', rank, 'is_me', false, 'is_filler', true) order by rank)
        from filler_rows), '[]'::jsonb)) else '{}'::jsonb end
    into result;
  return result;
end;
$$;
revoke all on function public.leaderboard_sync(bigint, boolean, text, boolean, text, integer, integer) from public, anon;
grant execute on function public.leaderboard_sync(bigint, boolean, text, boolean, text, integer, integer) to authenticated;

create table if not exists leaderboard_dev_private.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 18 and nickname = btrim(nickname) and nickname !~ '[[:cntrl:]]'),
  character_id integer not null check (character_id between 1 and 2),
  frame_id integer not null check (frame_id between 1 and 5),
  updated_at timestamptz not null default clock_timestamp()
);
alter table leaderboard_dev_private.profiles enable row level security;
revoke all on leaderboard_dev_private.profiles from public, anon, authenticated;
drop function if exists public.leaderboard_sync_dev(bigint, boolean, text, boolean);
create or replace function public.leaderboard_sync_dev(p_stars bigint default null, p_include_top boolean default true, p_language text default 'en', p_seed_fillers boolean default false, p_nickname text default null, p_character_id integer default null, p_frame_id integer default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  result jsonb;
  board_language text := case when lower(split_part(replace(coalesce(p_language, 'en'), '_', '-'), '-', 1)) = 'ru' then 'ru' else 'en' end;
  cis_percentage integer := case when board_language = 'ru' then 60 else 20 end;
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_include_top is null or p_seed_fillers is null or (p_stars is not null and (p_stars < 0 or p_stars > 2000000000)) then
    raise exception 'Invalid leaderboard payload' using errcode = '22023';
  end if;
  -- A profile can exist without a ranked score. Legacy clients never erase it.
  if p_nickname is not null or p_character_id is not null or p_frame_id is not null then
    if p_nickname is null or p_character_id is null or p_frame_id is null
      or char_length(p_nickname) not between 2 and 18 or p_nickname <> btrim(p_nickname)
      or p_nickname ~ '[[:cntrl:]]' or p_character_id not between 1 and 2 or p_frame_id not between 1 and 5 then
      raise exception 'Invalid player profile' using errcode = '22023';
    end if;
    insert into leaderboard_dev_private.profiles as existing(user_id, nickname, character_id, frame_id)
      values (player, p_nickname, p_character_id, p_frame_id)
    on conflict (user_id) do update set nickname = excluded.nickname,
      character_id = excluded.character_id, frame_id = excluded.frame_id, updated_at = clock_timestamp()
      where (existing.nickname, existing.character_id, existing.frame_id)
        is distinct from (excluded.nickname, excluded.character_id, excluded.frame_id);
  end if;
  if p_stars is not null and p_stars > 0 then
    insert into leaderboard_dev_private.players as existing(user_id, stars) values (player, p_stars)
    on conflict (user_id) do update
      set stars = excluded.stars, reached_at = clock_timestamp()
      where excluded.stars > existing.stars;
  end if;
  -- All reads (top and own position) share one statement snapshot.
  with population as (select count(*) as total from leaderboard_dev_private.players where stars > 0), mine as (
    select m.player_id, m.stars, m.reached_at, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id,
      1 + (select count(*) from leaderboard_dev_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))) as rank
    from leaderboard_dev_private.players m left join leaderboard_dev_private.profiles profile on profile.user_id = m.user_id where m.user_id = player and m.stars > 0
  ), top_players as (
    select p.player_id, p.stars, p.reached_at, p.user_id = player as is_me, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id
    from leaderboard_dev_private.players p left join leaderboard_dev_private.profiles profile on profile.user_id = p.user_id where p_include_top and p.stars > 0
    order by p.stars desc, p.reached_at, p.player_id limit 100
  ), ranked_top as (
    select player_id, stars, is_me, nickname, character_id, frame_id,
      row_number() over (order by stars desc, reached_at, player_id) as rank
    from top_players
  ), scored_fillers as (
    select f.*, row_number() over (partition by f.pool
      order by md5('pick:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text), f.slot) as pool_rank
    from leaderboard_dev_private.fillers f
    where p_include_top and p_seed_fillers and (select total from population) < 100
  ), chosen_fillers as (
    select f.* from scored_fillers f
    where f.pool_rank <= case when f.pool='cis' then cis_percentage else 100-cis_percentage end
  ), filler_values as (
    select 'filler:' || f.pool || ':' || lpad(f.slot::text, 3, '0') as player_id,
      f.nickname,
      30 + (('x' || substr(md5('stars:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text),1,8))::bit(32)::bigint % 71) as stars
    from chosen_fillers f
  ), filler_rows as (
    select f.*, 1 + (('x' || substr(md5(player_id),1,8))::bit(32)::bigint % 2)::integer as character_id,
      1 + (('x' || substr(md5('frame:' || player_id),1,8))::bit(32)::bigint % 5)::integer as frame_id, false as is_me, true as is_filler,
      row_number() over (order by stars desc, player_id) as rank from filler_values f
  ), display_top as (
    select player_id::text as player_id,
      coalesce(nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || player_id::text) as nickname, character_id, frame_id,
      stars, is_me, false as is_filler, rank from ranked_top
  )
  select jsonb_build_object('ok', true, 'protocol_version', 2, 'owner_id', player::text, 'language', board_language, 'total_players', (select total from population), 'me',
    (select jsonb_build_object('player_id', player_id::text,
      'nickname', coalesce(nickname, (case when board_language = 'ru' then 'Игрок ' else 'Player ' end) || player_id::text), 'character_id', character_id, 'frame_id', frame_id,
      'is_filler', false, 'stars', stars,
      'rank', case when rank <= 100 then rank else null end,
      'top_percent', case when rank > 100 then
        ceil(100::numeric * rank / (select total from population))::integer else null end) from mine))
    || case when p_include_top then jsonb_build_object('top',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id, 'nickname', nickname, 'character_id', character_id, 'frame_id', frame_id, 'stars', stars, 'rank', rank, 'is_me', is_me, 'is_filler', is_filler) order by rank)
        from display_top), '[]'::jsonb)) else '{}'::jsonb end
    || case when p_include_top and p_seed_fillers then jsonb_build_object('fillers',
      coalesce((select jsonb_agg(jsonb_build_object(
        'player_id', player_id, 'nickname', nickname, 'character_id', character_id, 'frame_id', frame_id, 'stars', stars, 'rank', rank, 'is_me', false, 'is_filler', true) order by rank)
        from filler_rows), '[]'::jsonb)) else '{}'::jsonb end
    into result;
  return result;
end;
$$;
revoke all on function public.leaderboard_sync_dev(bigint, boolean, text, boolean, text, integer, integer) from public, anon;
grant execute on function public.leaderboard_sync_dev(bigint, boolean, text, boolean, text, integer, integer) to authenticated;

notify pgrst, 'reload schema';
commit;
