-- Apply after 016. Keep legacy RPC signatures; add bounded quiz batches.
begin;
set local lock_timeout = '5s';

-- Block participant writes while initializing the exact counter and its triggers.
lock table leaderboard_private.players in share row exclusive mode;
create table if not exists leaderboard_private.population (
  singleton boolean primary key default true check (singleton),
  total bigint not null check (total >= 0)
);
alter table leaderboard_private.population enable row level security;
revoke all on leaderboard_private.population from public, anon, authenticated, service_role;
insert into leaderboard_private.population(singleton,total)
  select true,count(*) from leaderboard_private.players where stars > 0
  on conflict (singleton) do update set total = excluded.total;

create or replace function leaderboard_private.maintain_population()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  delta bigint := 0;
begin
  if TG_OP = 'TRUNCATE' then
    update leaderboard_private.population set total = 0 where singleton;
    return null;
  end if;
  if TG_OP in ('DELETE','UPDATE') and OLD.stars > 0 then delta := delta - 1; end if;
  if TG_OP in ('INSERT','UPDATE') and NEW.stars > 0 then delta := delta + 1; end if;
  if delta <> 0 then
    update leaderboard_private.population set total = total + delta where singleton;
    if not found then raise exception 'Missing leaderboard population counter'; end if;
  end if;
  return null;
end;
$$;
revoke all on function leaderboard_private.maintain_population() from public, anon, authenticated, service_role;
drop trigger if exists players_population_change on leaderboard_private.players;
create trigger players_population_change after insert or delete or update of stars on leaderboard_private.players
  for each row execute function leaderboard_private.maintain_population();
drop trigger if exists players_population_truncate on leaderboard_private.players;
create trigger players_population_truncate after truncate on leaderboard_private.players
  for each statement execute function leaderboard_private.maintain_population();

-- Block participant writes while initializing the exact counter and its triggers.
lock table leaderboard_dev_private.players in share row exclusive mode;
create table if not exists leaderboard_dev_private.population (
  singleton boolean primary key default true check (singleton),
  total bigint not null check (total >= 0)
);
alter table leaderboard_dev_private.population enable row level security;
revoke all on leaderboard_dev_private.population from public, anon, authenticated, service_role;
insert into leaderboard_dev_private.population(singleton,total)
  select true,count(*) from leaderboard_dev_private.players where stars > 0
  on conflict (singleton) do update set total = excluded.total;

create or replace function leaderboard_dev_private.maintain_population()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  delta bigint := 0;
begin
  if TG_OP = 'TRUNCATE' then
    update leaderboard_dev_private.population set total = 0 where singleton;
    return null;
  end if;
  if TG_OP in ('DELETE','UPDATE') and OLD.stars > 0 then delta := delta - 1; end if;
  if TG_OP in ('INSERT','UPDATE') and NEW.stars > 0 then delta := delta + 1; end if;
  if delta <> 0 then
    update leaderboard_dev_private.population set total = total + delta where singleton;
    if not found then raise exception 'Missing leaderboard population counter'; end if;
  end if;
  return null;
end;
$$;
revoke all on function leaderboard_dev_private.maintain_population() from public, anon, authenticated, service_role;
drop trigger if exists players_population_change on leaderboard_dev_private.players;
create trigger players_population_change after insert or delete or update of stars on leaderboard_dev_private.players
  for each row execute function leaderboard_dev_private.maintain_population();
drop trigger if exists players_population_truncate on leaderboard_dev_private.players;
create trigger players_population_truncate after truncate on leaderboard_dev_private.players
  for each statement execute function leaderboard_dev_private.maintain_population();

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
  with population as (select total from leaderboard_private.population where singleton), mine as (
    select m.player_id, m.stars, m.reached_at, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id,
      1 + (select count(*) from (
        select 1 from leaderboard_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))
        limit 100
      ) as ahead) as rank
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
      f.nickname, f.character_id, f.frame_id,
      30 + (('x' || substr(md5('stars:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text),1,8))::bit(32)::bigint % 71) as stars
    from chosen_fillers f
  ), filler_rows as (
    select f.*, false as is_me, true as is_filler,
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
      -- Reserved protocol-v2 compatibility field; no percentile calculation.
      'top_percent', case when rank > 100 then 100 else null end) from mine))
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
  with population as (select total from leaderboard_dev_private.population where singleton), mine as (
    select m.player_id, m.stars, m.reached_at, profile.nickname, coalesce(profile.character_id, 1) as character_id, coalesce(profile.frame_id, 4) as frame_id,
      1 + (select count(*) from (
        select 1 from leaderboard_dev_private.players p
        where p.stars > m.stars
          or (p.stars = m.stars and (p.reached_at, p.player_id) < (m.reached_at, m.player_id))
        limit 100
      ) as ahead) as rank
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
      f.nickname, f.character_id, f.frame_id,
      30 + (('x' || substr(md5('stars:v3:' || player::text || ':' || board_language || ':' || f.pool || ':' || f.slot::text),1,8))::bit(32)::bigint % 71) as stars
    from chosen_fillers f
  ), filler_rows as (
    select f.*, false as is_me, true as is_filler,
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
      -- Reserved protocol-v2 compatibility field; no percentile calculation.
      'top_percent', case when rank > 100 then 100 else null end) from mine))
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

create or replace function public.quiz_answer(p_key text, p_answer integer default -1, p_include_counts boolean default true)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  question_slot integer;
  bits bytea;
  byte_index integer;
  mask integer;
  result_counts bigint[];
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_answer is null or p_answer < -2 or p_answer > 3 then
    raise exception 'Invalid answer' using errcode = '22023';
  end if;
  -- Wire keys stay textual for published clients and their persisted queues.
  if p_key is null or p_key !~ '^(ru|en):[1-9][0-9]*:[0-9a-f]{64}$' then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if length(split_part(p_key, ':', 2)) > 10 then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if split_part(p_key, ':', 2)::bigint > 2147483647 then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if p_answer = -1 then
    -- Prefetch resolves the key, counters and own attempt in one indexed query.
    select q.slot, q.counts, p.seen into question_slot, result_counts, bits
      from quiz_private.questions q left join quiz_private.players p on p.user_id = player
      where q.language = split_part(p_key, ':', 1)
        and q.question_id = split_part(p_key, ':', 2)::integer
        and q.revision_hash = decode(split_part(p_key, ':', 3), 'hex');
    if question_slot is null then
      raise exception 'Unknown question version' using errcode = '22023';
    end if;
    if not p_include_counts then return jsonb_build_object('ok', true); end if;
    byte_index := (question_slot - 1) / 8;
    mask := 1 << ((question_slot - 1) % 8);
    if bits is null or octet_length(bits) <= byte_index then
      mask := 0;
    else
      mask := get_byte(bits, byte_index) & mask;
    end if;
    return jsonb_build_object('ok', true, 'counts', to_jsonb(result_counts), 'already_answered', mask != 0);
  end if;
  select slot into question_slot from quiz_private.questions
    where language = split_part(p_key, ':', 1)
      and question_id = split_part(p_key, ':', 2)::integer
      and revision_hash = decode(split_part(p_key, ':', 3), 'hex');
  if question_slot is null then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if p_answer != -1 then
    insert into quiz_private.players(user_id) values (player) on conflict do nothing;
    select seen into bits from quiz_private.players where user_id = player for update;
    byte_index := (question_slot - 1) / 8;
    mask := 1 << ((question_slot - 1) % 8);
    if octet_length(bits) <= byte_index then
      bits := bits || decode(repeat('00', byte_index + 1 - octet_length(bits)), 'hex');
    end if;
    if (get_byte(bits, byte_index) & mask) = 0 then
      update quiz_private.players set seen = set_byte(bits, byte_index, get_byte(bits, byte_index) | mask)
        where user_id = player;
      if p_answer >= 0 then
        update quiz_private.questions set counts[p_answer + 1] = counts[p_answer + 1] + 1
          where slot = question_slot;
      end if;
    end if;
  end if;
  if not p_include_counts then
    return jsonb_build_object('ok', true);
  end if;
  -- Read counters and seen flag from one consistent snapshot.
  select q.counts, p.seen into result_counts, bits
    from quiz_private.questions q
    left join quiz_private.players p on p.user_id = player
    where q.slot = question_slot;
  byte_index := (question_slot - 1) / 8;
  mask := 1 << ((question_slot - 1) % 8);
  -- Reads do not create player rows or consume the first attempt.
  if bits is null or octet_length(bits) <= byte_index then
    mask := 0;
  else
    mask := get_byte(bits, byte_index) & mask;
  end if;
  return jsonb_build_object('ok', true, 'counts', to_jsonb(result_counts), 'already_answered', mask != 0);
end;
$$;
revoke all on function public.quiz_answer(text, integer, boolean) from public, anon;
grant execute on function public.quiz_answer(text, integer, boolean) to authenticated;


create or replace function public.quiz_answer_dev(p_key text, p_answer integer default -1, p_include_counts boolean default true)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  player uuid := auth.uid();
  question_slot integer;
  bits bytea;
  byte_index integer;
  mask integer;
  result_counts bigint[];
begin
  if player is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if p_answer is null or p_answer < -2 or p_answer > 3 then
    raise exception 'Invalid answer' using errcode = '22023';
  end if;
  -- Wire keys stay textual for published clients and their persisted queues.
  if p_key is null or p_key !~ '^(ru|en):[1-9][0-9]*:[0-9a-f]{64}$' then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if length(split_part(p_key, ':', 2)) > 10 then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if split_part(p_key, ':', 2)::bigint > 2147483647 then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if p_answer = -1 then
    -- Prefetch resolves the key, counters and own attempt in one indexed query.
    select q.slot, q.counts, p.seen into question_slot, result_counts, bits
      from quiz_dev_private.questions q left join quiz_dev_private.players p on p.user_id = player
      where q.language = split_part(p_key, ':', 1)
        and q.question_id = split_part(p_key, ':', 2)::integer
        and q.revision_hash = decode(split_part(p_key, ':', 3), 'hex');
    if question_slot is null then
      raise exception 'Unknown question version' using errcode = '22023';
    end if;
    if not p_include_counts then return jsonb_build_object('ok', true); end if;
    byte_index := (question_slot - 1) / 8;
    mask := 1 << ((question_slot - 1) % 8);
    if bits is null or octet_length(bits) <= byte_index then
      mask := 0;
    else
      mask := get_byte(bits, byte_index) & mask;
    end if;
    return jsonb_build_object('ok', true, 'counts', to_jsonb(result_counts), 'already_answered', mask != 0);
  end if;
  select slot into question_slot from quiz_dev_private.questions
    where language = split_part(p_key, ':', 1)
      and question_id = split_part(p_key, ':', 2)::integer
      and revision_hash = decode(split_part(p_key, ':', 3), 'hex');
  if question_slot is null then
    raise exception 'Unknown question version' using errcode = '22023';
  end if;
  if p_answer != -1 then
    insert into quiz_dev_private.players(user_id) values (player) on conflict do nothing;
    select seen into bits from quiz_dev_private.players where user_id = player for update;
    byte_index := (question_slot - 1) / 8;
    mask := 1 << ((question_slot - 1) % 8);
    if octet_length(bits) <= byte_index then
      bits := bits || decode(repeat('00', byte_index + 1 - octet_length(bits)), 'hex');
    end if;
    if (get_byte(bits, byte_index) & mask) = 0 then
      update quiz_dev_private.players set seen = set_byte(bits, byte_index, get_byte(bits, byte_index) | mask)
        where user_id = player;
      if p_answer >= 0 then
        update quiz_dev_private.questions set counts[p_answer + 1] = counts[p_answer + 1] + 1
          where slot = question_slot;
      end if;
    end if;
  end if;
  if not p_include_counts then
    return jsonb_build_object('ok', true);
  end if;
  -- Read counters and seen flag from one consistent snapshot.
  select q.counts, p.seen into result_counts, bits
    from quiz_dev_private.questions q
    left join quiz_dev_private.players p on p.user_id = player
    where q.slot = question_slot;
  byte_index := (question_slot - 1) / 8;
  mask := 1 << ((question_slot - 1) % 8);
  -- Reads do not create player rows or consume the first attempt.
  if bits is null or octet_length(bits) <= byte_index then
    mask := 0;
  else
    mask := get_byte(bits, byte_index) & mask;
  end if;
  return jsonb_build_object('ok', true, 'counts', to_jsonb(result_counts), 'already_answered', mask != 0);
end;
$$;
revoke all on function public.quiz_answer_dev(text, integer, boolean) from public, anon;
grant execute on function public.quiz_answer_dev(text, integer, boolean) to authenticated;


-- Each valid item commits once; unknown catalog revisions do not block other votes.
-- Unexpected database failures still abort the whole batch, which is safe to retry.
create or replace function public.quiz_answers(p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  entry jsonb;
  item jsonb;
  results jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Invalid quiz batch' using errcode = '22023';
  end if;
  if jsonb_array_length(p_answers) not between 1 and 20 then
    raise exception 'Quiz batch must contain 1..20 items' using errcode = '22023';
  end if;
  for entry in select value from jsonb_array_elements(p_answers) loop
    item := jsonb_build_object('p_key',entry->'p_key','p_answer',entry->'p_answer');
    if jsonb_typeof(entry) is distinct from 'object'
      or jsonb_typeof(entry->'p_key') is distinct from 'string'
      or entry->'p_answer' is null or entry->'p_answer' not in ('-2'::jsonb,'-1'::jsonb,'0'::jsonb,'1'::jsonb,'2'::jsonb,'3'::jsonb)
      or (entry ? 'p_include_counts' and jsonb_typeof(entry->'p_include_counts') is distinct from 'boolean') then
      item := item || jsonb_build_object('ok',false,'code','22023');
    else
      begin
        item := item || public.quiz_answer(entry->>'p_key',(entry->>'p_answer')::numeric::integer,
          coalesce((entry->>'p_include_counts')::boolean,true));
      exception when sqlstate '22023' then
        item := item || jsonb_build_object('ok',false,'code','22023');
      end;
    end if;
    results := results || jsonb_build_array(item);
  end loop;
  return jsonb_build_object('ok',true,'results',results);
end;
$$;
revoke all on function public.quiz_answers(jsonb) from public, anon;
grant execute on function public.quiz_answers(jsonb) to authenticated;

-- Each valid item commits once; unknown catalog revisions do not block other votes.
-- Unexpected database failures still abort the whole batch, which is safe to retry.
create or replace function public.quiz_answers_dev(p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  entry jsonb;
  item jsonb;
  results jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Invalid quiz batch' using errcode = '22023';
  end if;
  if jsonb_array_length(p_answers) not between 1 and 20 then
    raise exception 'Quiz batch must contain 1..20 items' using errcode = '22023';
  end if;
  for entry in select value from jsonb_array_elements(p_answers) loop
    item := jsonb_build_object('p_key',entry->'p_key','p_answer',entry->'p_answer');
    if jsonb_typeof(entry) is distinct from 'object'
      or jsonb_typeof(entry->'p_key') is distinct from 'string'
      or entry->'p_answer' is null or entry->'p_answer' not in ('-2'::jsonb,'-1'::jsonb,'0'::jsonb,'1'::jsonb,'2'::jsonb,'3'::jsonb)
      or (entry ? 'p_include_counts' and jsonb_typeof(entry->'p_include_counts') is distinct from 'boolean') then
      item := item || jsonb_build_object('ok',false,'code','22023');
    else
      begin
        item := item || public.quiz_answer_dev(entry->>'p_key',(entry->>'p_answer')::numeric::integer,
          coalesce((entry->>'p_include_counts')::boolean,true));
      exception when sqlstate '22023' then
        item := item || jsonb_build_object('ok',false,'code','22023');
      end;
    end if;
    results := results || jsonb_build_array(item);
  end loop;
  return jsonb_build_object('ok',true,'results',results);
end;
$$;
revoke all on function public.quiz_answers_dev(jsonb) from public, anon;
grant execute on function public.quiz_answers_dev(jsonb) to authenticated;

notify pgrst, 'reload schema';
commit;
