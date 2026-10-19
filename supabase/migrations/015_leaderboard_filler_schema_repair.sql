-- Repair the table half of migration 013 if newer RPCs were installed first.
-- Keep existing names, appearances, scores, privileges and the 014 functions.
begin;

alter table leaderboard_private.fillers add column if not exists character_id integer;
alter table leaderboard_private.fillers add column if not exists frame_id integer;
alter table leaderboard_dev_private.fillers add column if not exists character_id integer;
alter table leaderboard_dev_private.fillers add column if not exists frame_id integer;

-- Match the published appearance IDs used by 011 and the canonical 013 seed.
-- Fill only missing values: deployed/customized appearances remain untouched.
update leaderboard_private.fillers
set character_id = coalesce(character_id,
    1 + (('x' || substr(md5('filler:' || pool || ':' || lpad(slot::text, 3, '0')), 1, 8))::bit(32)::bigint % 2)::integer),
  frame_id = coalesce(frame_id,
    1 + (('x' || substr(md5('frame:filler:' || pool || ':' || lpad(slot::text, 3, '0')), 1, 8))::bit(32)::bigint % 5)::integer)
where character_id is null or frame_id is null;

update leaderboard_dev_private.fillers
set character_id = coalesce(character_id,
    1 + (('x' || substr(md5('filler:' || pool || ':' || lpad(slot::text, 3, '0')), 1, 8))::bit(32)::bigint % 2)::integer),
  frame_id = coalesce(frame_id,
    1 + (('x' || substr(md5('frame:filler:' || pool || ':' || lpad(slot::text, 3, '0')), 1, 8))::bit(32)::bigint % 5)::integer)
where character_id is null or frame_id is null;

alter table leaderboard_private.fillers alter column character_id set not null;
alter table leaderboard_private.fillers alter column frame_id set not null;
alter table leaderboard_private.fillers drop constraint if exists fillers_character_id_check;
alter table leaderboard_private.fillers add constraint fillers_character_id_check check (character_id between 1 and 2);
alter table leaderboard_private.fillers drop constraint if exists fillers_frame_id_check;
alter table leaderboard_private.fillers add constraint fillers_frame_id_check check (frame_id between 1 and 5);

alter table leaderboard_dev_private.fillers alter column character_id set not null;
alter table leaderboard_dev_private.fillers alter column frame_id set not null;
alter table leaderboard_dev_private.fillers drop constraint if exists fillers_character_id_check;
alter table leaderboard_dev_private.fillers add constraint fillers_character_id_check check (character_id between 1 and 2);
alter table leaderboard_dev_private.fillers drop constraint if exists fillers_frame_id_check;
alter table leaderboard_dev_private.fillers add constraint fillers_frame_id_check check (frame_id between 1 and 5);

commit;
