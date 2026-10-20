-- Apply after 015. Preserve RPC signatures, published IDs, slots, votes and seen bits.
-- Table rewrites take exclusive locks; schedule this migration outside active play.
begin;
set local lock_timeout = '5s';

alter table leaderboard_private.players alter column stars type integer using stars::integer;
alter table leaderboard_private.profiles
  alter column character_id type smallint using character_id::smallint,
  alter column frame_id type smallint using frame_id::smallint;
alter table leaderboard_private.fillers
  alter column character_id type smallint using character_id::smallint,
  alter column frame_id type smallint using frame_id::smallint;

alter table leaderboard_dev_private.players alter column stars type integer using stars::integer;
alter table leaderboard_dev_private.profiles
  alter column character_id type smallint using character_id::smallint,
  alter column frame_id type smallint using frame_id::smallint;
alter table leaderboard_dev_private.fillers
  alter column character_id type smallint using character_id::smallint,
  alter column frame_id type smallint using frame_id::smallint;

-- Refuse unknown legacy key formats instead of silently losing catalog identities.
-- Existing identity sequences and slot values are never reset or regenerated.
do $migration$
declare
  schema_name text;
  strict_invalid_key boolean;
begin
  foreach schema_name in array array['quiz_private', 'quiz_dev_private'] loop
    if exists (select 1 from information_schema.columns c
      where c.table_schema = schema_name and c.table_name = 'questions' and c.column_name = 'question_key') then
      execute format($sql$select exists(select 1 from %I.questions
        where question_key !~ '^(ru|en):[1-9][0-9]*:[0-9a-f]{64}$')$sql$, schema_name) into strict_invalid_key;
      if strict_invalid_key then
        raise exception 'Invalid legacy quiz key in %.questions; migration cancelled', schema_name;
      end if;
      execute format('alter table %I.questions add column language text, add column question_id integer, add column revision_hash bytea', schema_name);
      execute format($sql$update %I.questions set language = split_part(question_key, ':', 1),
        question_id = split_part(question_key, ':', 2)::integer,
        revision_hash = decode(split_part(question_key, ':', 3), 'hex')$sql$, schema_name);
      execute format('alter table %I.questions alter column language set not null,
        alter column question_id set not null, alter column revision_hash set not null,
        add constraint questions_language_check check (language in (''ru'', ''en'')),
        add constraint questions_question_id_check check (question_id > 0),
        add constraint questions_revision_hash_check check (octet_length(revision_hash) = 32),
        add constraint questions_identity_key unique (language, question_id, revision_hash),
        drop column question_key', schema_name);
      -- Reclaim the dropped text and update versions now, preserving slot/identity values.
      execute format('cluster %I.questions using questions_pkey', schema_name);
      execute format('analyze %I.questions', schema_name);
    end if;
  end loop;
end;
$migration$;

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


notify pgrst, 'reload schema';
commit;
