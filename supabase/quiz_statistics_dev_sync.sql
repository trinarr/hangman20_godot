-- Requires migration 016. Run after each production catalog update.
begin;
-- Copy only catalog identities, never production counts or player records.
-- Slot allocation is independent; existing dev bit positions remain stable.
insert into quiz_dev_private.questions(language, question_id, revision_hash)
select q.language, q.question_id, q.revision_hash from quiz_private.questions q
where not exists (select 1 from quiz_dev_private.questions d
  where (d.language, d.question_id, d.revision_hash) = (q.language, q.question_id, q.revision_hash))
order by q.slot
on conflict (language, question_id, revision_hash) do nothing;
commit;
