-- Apply after 005. Preserve every record; change only the returned position.
begin;
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
  with population as (select count(*) as total from leaderboard_private.players), mine as (
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
  select jsonb_build_object('ok', true, 'total_players', (select total from population), 'me',
    (select jsonb_build_object('player_id', player_id::text, 'stars', stars,
      'rank', case when rank <= 100 then rank else null end,
      'top_percent', case when rank > 100 then
        ceil(100::numeric * rank / (select total from population))::integer else null end) from mine))
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
  with population as (select count(*) as total from leaderboard_dev_private.players), mine as (
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
  select jsonb_build_object('ok', true, 'total_players', (select total from population), 'me',
    (select jsonb_build_object('player_id', player_id::text, 'stars', stars,
      'rank', case when rank <= 100 then rank else null end,
      'top_percent', case when rank > 100 then
        ceil(100::numeric * rank / (select total from population))::integer else null end) from mine))
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
