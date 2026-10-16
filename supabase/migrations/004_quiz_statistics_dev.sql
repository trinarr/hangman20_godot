-- Apply after 001, 002 and 003. Safe to rerun; existing dev votes are preserved.
begin;
create schema if not exists quiz_dev_private;
revoke all on schema quiz_dev_private from public, anon, authenticated;

create table if not exists quiz_dev_private.questions (
  slot integer generated always as identity primary key,
  question_key text not null unique,
  counts bigint[] not null default array[0,0,0,0]::bigint[]
);
create table if not exists quiz_dev_private.players (
  user_id uuid primary key references auth.users(id) on delete cascade,
  seen bytea not null default ''::bytea
);
alter table quiz_dev_private.questions enable row level security;
alter table quiz_dev_private.players enable row level security;
revoke all on all tables in schema quiz_dev_private from public, anon, authenticated;
revoke all on all sequences in schema quiz_dev_private from public, anon, authenticated;


-- Copy only catalog identities, never production counts or player records.
-- Slot allocation is independent; existing dev bit positions remain stable.
insert into quiz_dev_private.questions(question_key)
select q.question_key from quiz_private.questions q
where not exists (select 1 from quiz_dev_private.questions d where d.question_key = q.question_key)
order by q.slot
on conflict (question_key) do nothing;

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
  select slot into question_slot from quiz_dev_private.questions where question_key = p_key;
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

commit;
