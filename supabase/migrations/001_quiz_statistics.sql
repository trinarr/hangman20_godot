-- Run once in Supabase SQL Editor. Application writes only through quiz_answer.
create schema if not exists quiz_private;
revoke all on schema quiz_private from public, anon, authenticated;

create table if not exists quiz_private.questions (
  slot integer generated always as identity primary key,
  question_key text not null unique,
  counts bigint[] not null default array[0,0,0,0]::bigint[]
);
create table if not exists quiz_private.players (
  user_id uuid primary key references auth.users(id) on delete cascade,
  seen bytea not null default ''::bytea
);
alter table quiz_private.questions enable row level security;
alter table quiz_private.players enable row level security;
revoke all on all tables in schema quiz_private from public, anon, authenticated;
revoke all on all sequences in schema quiz_private from public, anon, authenticated;

-- p_answer: catalog index (0..3), -1 reads only, -2 marks a hinted first attempt without a vote.
-- Row lock serializes all requests for one player, including concurrent retries.
-- The seen bit and counter increment commit in the same transaction.
create or replace function public.quiz_answer(p_key text, p_answer integer default -1)
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
  select slot into question_slot from quiz_private.questions where question_key = p_key;
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
  select counts into result_counts from quiz_private.questions where slot = question_slot;
  return jsonb_build_object('counts', to_jsonb(result_counts));
end;
$$;
revoke all on function public.quiz_answer(text, integer) from public, anon;
grant execute on function public.quiz_answer(text, integer) to authenticated;
