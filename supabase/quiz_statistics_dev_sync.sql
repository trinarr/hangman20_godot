-- Run after each production catalog update. Does not copy votes or reset either environment.
begin;
-- Copy only catalog identities, never production counts or player records.
-- Slot allocation is independent; existing dev bit positions remain stable.
insert into quiz_dev_private.questions(question_key)
select q.question_key from quiz_private.questions q
where not exists (select 1 from quiz_dev_private.questions d where d.question_key = q.question_key)
order by q.slot
on conflict (question_key) do nothing;
commit;
