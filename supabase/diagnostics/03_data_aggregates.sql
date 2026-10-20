-- Exact aggregate scans of application tables; run during low load.
-- No raw user IDs, nicknames, question keys, seen bitmaps or Auth rows are returned.
-- Dynamic SELECTs handle missing relations without invoking application RPCs.
with
targets(schema_name,table_name,kind) as (
  select s.schema_name,t.table_name,t.kind from
    (values ('leaderboard_private'),('leaderboard_dev_private')) s(schema_name)
    cross join (values ('players','scores'),('profiles','profiles'),('fillers','fillers')) t(table_name,kind)
  union all
  select s.schema_name,t.table_name,t.kind from
    (values ('quiz_private'),('quiz_dev_private')) s(schema_name)
    cross join (values ('questions','questions'),('players','quiz_players')) t(table_name,kind)
),
templates(kind,sql_template) as (values
('scores',$query$
  select jsonb_build_object('rows',count(*),
    'positive_scores',count(*) filter(where stars>0),
    'invalid_stars',count(*) filter(where stars is null or stars<0 or stars>2000000000),
    'zero_scores',count(*) filter(where stars=0),
    'min_stars',min(stars),'max_stars',max(stars),
    'missing_user_id',count(*) filter(where nullif(p->>'user_id','') is null),
    'duplicate_user_ids',count(p->>'user_id')-count(distinct p->>'user_id'),
    'missing_reached_at',count(*) filter(where p->>'reached_at' is null)) as payload
  from (select p,case when jsonb_typeof(p->'stars')='number' and p->>'stars' ~ '^-?[0-9]+$'
    then (p->>'stars')::numeric end as stars from (select to_jsonb(t) as p from %I.%I t) a) b
$query$),
('profiles',$query$
  select jsonb_build_object('rows',count(*),
    'invalid_nickname',count(*) filter(where coalesce(length(p->>'nickname'),0) not between 2 and 18
      or p->>'nickname'<>btrim(p->>'nickname') or p->>'nickname' ~ '[[:cntrl:]]'),
    'invalid_character_id',count(*) filter(where coalesce(p->>'character_id','') not in ('1','2')),
    'invalid_frame_id',count(*) filter(where coalesce(p->>'frame_id','') not in ('1','2','3','4','5')),
    'missing_user_id',count(*) filter(where nullif(p->>'user_id','') is null),
    'duplicate_user_ids',count(p->>'user_id')-count(distinct p->>'user_id'),
    'missing_updated_at',count(*) filter(where p->>'updated_at' is null)) as payload
  from (select to_jsonb(t) as p from %I.%I t) a
$query$),
('fillers',$query$
  select jsonb_build_object('rows',count(*),
    'cis_rows',count(*) filter(where p->>'pool'='cis'),
    'us_europe_rows',count(*) filter(where p->>'pool'='us_europe'),
    'invalid_pool',count(*) filter(where coalesce(p->>'pool','') not in ('cis','us_europe')),
    'invalid_slot',count(*) filter(where coalesce(p->>'slot','') !~ '^[1-9][0-9]?$|^100$'),
    'duplicate_pool_slot',count(*)-count(distinct jsonb_build_array(p->>'pool',p->>'slot')),
    'invalid_nickname',count(*) filter(where coalesce(length(p->>'nickname'),0) not between 2 and 18
      or p->>'nickname'<>btrim(p->>'nickname') or p->>'nickname' ~ '[[:space:][:cntrl:]]'),
    'duplicate_nicknames_case_insensitive',count(p->>'nickname')-count(distinct lower(p->>'nickname')),
    'casual_rows',count(*) filter(where p->>'style'='casual'),
    'slang_rows',count(*) filter(where p->>'style'='slang'),
    'invalid_style',count(*) filter(where coalesce(p->>'style','') not in ('casual','slang')),
    'invalid_or_missing_character_id',count(*) filter(where coalesce(p->>'character_id','') not in ('1','2')),
    'invalid_or_missing_frame_id',count(*) filter(where coalesce(p->>'frame_id','') not in ('1','2','3','4','5'))) as payload
  from (select to_jsonb(t) as p from %I.%I t) a
$query$),
('questions',$query$
  select jsonb_build_object('rows',count(*),
    'missing_question_key',count(*) filter(where nullif(p->>'question_key','') is null),
    'duplicate_question_keys',count(p->>'question_key')-count(distinct p->>'question_key'),
    'duplicate_slots',count(p->>'slot')-count(distinct p->>'slot'),
    'ru_rows',count(*) filter(where p->>'question_key' like 'ru:%%'),
    'en_rows',count(*) filter(where p->>'question_key' like 'en:%%'),
    'other_language_rows',count(*) filter(where coalesce(p->>'question_key','') not like 'ru:%%' and coalesce(p->>'question_key','') not like 'en:%%'),
    'invalid_counts_shape',count(*) filter(where case when jsonb_typeof(p->'counts')='array' then jsonb_array_length(p->'counts') else -1 end <> 4),
    'invalid_count_values',count(*) filter(where exists(select 1 from jsonb_array_elements(case when jsonb_typeof(p->'counts')='array' then p->'counts' else '[]'::jsonb end) v
      where jsonb_typeof(v)<>'number' or v#>>'{}' !~ '^[0-9]+$')),
    'total_recorded_votes',coalesce(sum((select coalesce(sum(case when jsonb_typeof(v)='number' and v#>>'{}' ~ '^[0-9]+$' then (v#>>'{}')::numeric else 0 end),0)
      from jsonb_array_elements(case when jsonb_typeof(p->'counts')='array' then p->'counts' else '[]'::jsonb end) v)),0)) as payload
  from (select to_jsonb(t) as p from %I.%I t) a
$query$),
('quiz_players',$query$
  select jsonb_build_object('rows',count(*),
    'missing_user_id',count(*) filter(where nullif(p->>'user_id','') is null),
    'duplicate_user_ids',count(p->>'user_id')-count(distinct p->>'user_id'),
    'missing_seen_bitmap',count(*) filter(where p->>'seen' is null),
    'maximum_seen_bytes',max(greatest((length(coalesce(p->>'seen',''))-2)/2,0))) as payload
  from (select to_jsonb(t) as p from %I.%I t) a
$query$)
),
resolved as (
  select t.*,c.oid as relation_oid,c.relkind,c.relnamespace,q.sql_template
  from targets t join templates q using(kind)
  left join pg_catalog.pg_namespace n on n.nspname=t.schema_name
  left join pg_catalog.pg_class c on c.relnamespace=n.oid and c.relname=t.table_name
),
reports as (
  select schema_name,table_name,case
    when relation_oid is null then jsonb_build_object('status','MISSING_TABLE')
    when relkind not in ('r','p') then jsonb_build_object('status','UNEXPECTED_RELATION_KIND','kind',relkind)
    when not pg_catalog.has_schema_privilege(relnamespace,'USAGE') or not pg_catalog.has_table_privilege(relation_oid,'SELECT')
      then jsonb_build_object('status','INSUFFICIENT_PRIVILEGE')
    else jsonb_build_object('status',case when pg_catalog.row_security_active(relation_oid) then 'FILTERED_BY_RLS' else 'OK' end,
      'metrics',((xpath('/row/payload/text()',pg_catalog.query_to_xml(format(sql_template,schema_name,table_name),false,true,'')))[1]::text)::jsonb)
    end as result
  from resolved
)
select jsonb_pretty(jsonb_build_object('report','hangman_data_v1','observed_at',statement_timestamp(),'sql_role',current_user,
  'tables',(select jsonb_agg(jsonb_build_object('schema',schema_name,'table',table_name,'result',result) order by schema_name,table_name) from reports)
)) as audit_report;
