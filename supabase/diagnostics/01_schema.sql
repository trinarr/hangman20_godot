-- Hangman diagnostics v1. One SELECT, no writes and no application RPC calls.
-- Save the audit_report cell as 01_schema.json, or export the result as CSV.
with
leader_schemas(schema_name) as (values ('leaderboard_private'), ('leaderboard_dev_private')),
quiz_schemas(schema_name) as (values ('quiz_private'), ('quiz_dev_private')),
expected_columns(schema_name, table_name, column_name, expected_type) as (
  select s.schema_name, c.* from leader_schemas s cross join (values
    ('players','player_id','bigint'), ('players','user_id','uuid'),
    ('players','stars','bigint'), ('players','reached_at','timestamp with time zone'),
    ('profiles','user_id','uuid'), ('profiles','nickname','text'),
    ('profiles','character_id','integer'), ('profiles','frame_id','integer'),
    ('profiles','updated_at','timestamp with time zone'),
    ('fillers','pool','text'), ('fillers','slot','integer'),
    ('fillers','nickname','text'), ('fillers','style','text'),
    ('fillers','character_id','integer'), ('fillers','frame_id','integer')
  ) c(table_name,column_name,expected_type)
  union all
  select s.schema_name, c.* from quiz_schemas s cross join (values
    ('questions','slot','integer'), ('questions','question_key','text'),
    ('questions','counts','bigint[]'), ('players','user_id','uuid'), ('players','seen','bytea')
  ) c(table_name,column_name,expected_type)
),
app_relations as (
  select n.nspname as schema_name, c.*
  from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private')
    and c.relkind in ('r','p','v','m','S','f')
),
column_checks as (
  select e.*, pg_catalog.format_type(a.atttypid,a.atttypmod) as actual_type,
    a.attnotnull as not_null,
    case when c.oid is null then 'MISSING_TABLE' when a.attnum is null then 'MISSING_COLUMN'
      when pg_catalog.format_type(a.atttypid,a.atttypmod)<>e.expected_type then 'TYPE_MISMATCH' else 'OK' end as status
  from expected_columns e
  left join pg_catalog.pg_namespace n on n.nspname=e.schema_name
  left join pg_catalog.pg_class c on c.relnamespace=n.oid and c.relname=e.table_name and c.relkind in ('r','p')
  left join pg_catalog.pg_attribute a on a.attrelid=c.oid and a.attname=e.column_name and a.attnum>0 and not a.attisdropped
),
expected_rpcs(name, arg_types) as (values
  ('leaderboard_sync','bigint, boolean, text, boolean, text, integer, integer'),
  ('leaderboard_sync_dev','bigint, boolean, text, boolean, text, integer, integer'),
  ('quiz_answer','text, integer, boolean'), ('quiz_answer_dev','text, integer, boolean')
),
rpc_checks as (
  select e.name, e.arg_types as expected_arg_types,
    count(p.oid) as overload_count,
    count(p.oid) filter(where pg_catalog.oidvectortypes(p.proargtypes)=e.arg_types) as matching_signatures,
    coalesce(jsonb_agg(jsonb_build_object('arg_types',pg_catalog.oidvectortypes(p.proargtypes),
      'arg_names',p.proargnames,'default_arg_count',p.pronargdefaults,
      'return_type',pg_catalog.pg_get_function_result(p.oid),'security_definer',p.prosecdef,
      'body_md5',md5(p.prosrc),'body_bytes',octet_length(p.prosrc))) filter(where p.oid is not null),'[]'::jsonb) as actual,
    case when count(p.oid)=0 then 'MISSING_RPC'
      when count(p.oid)>1 then 'REVIEW_OVERLOADS'
      when count(p.oid) filter(where pg_catalog.oidvectortypes(p.proargtypes)=e.arg_types)<>1 then 'SIGNATURE_MISMATCH'
      else 'OK' end as status
  from expected_rpcs e left join pg_catalog.pg_namespace n on n.nspname='public'
  left join pg_catalog.pg_proc p on p.pronamespace=n.oid and p.proname=e.name and p.prokind='f'
  group by e.name,e.arg_types
),
migration_relation as (
  select c.oid,n.oid as schema_oid from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname='supabase_migrations' and c.relname='schema_migrations' and c.relkind in ('r','p')
),
migration_history as (
  select case
    when (select oid from migration_relation) is null then jsonb_build_object('status','NOT_REGISTERED_OR_NOT_VISIBLE')
    when not pg_catalog.has_schema_privilege((select schema_oid from migration_relation),'USAGE')
      or not pg_catalog.has_table_privilege((select oid from migration_relation),'SELECT') then jsonb_build_object('status','INSUFFICIENT_PRIVILEGE')
    else jsonb_build_object('status','OK','versions',
      ((xpath('/row/payload/text()',pg_catalog.query_to_xml(
        $q$select coalesce(jsonb_agg(to_jsonb(m)->>'version' order by to_jsonb(m)->>'version'),'[]'::jsonb) as payload from supabase_migrations.schema_migrations m$q$,
        false,true,'')))[1]::text)::jsonb)
    end as report
)
select jsonb_pretty(jsonb_build_object(
  'report','hangman_schema_v1','observed_at',statement_timestamp(),
  'database',current_database(),'sql_role',current_user,'postgres_version',current_setting('server_version'),
  'column_checks',(select jsonb_agg(to_jsonb(c) order by schema_name,table_name,column_name) from column_checks c),
  'rpc_checks',(select jsonb_agg(to_jsonb(r) order by name) from rpc_checks r),
  'migration_history',(select report from migration_history),
  'relations',coalesce((select jsonb_agg(jsonb_build_object('schema',schema_name,'name',relname,'kind',relkind,
    'rls_enabled',relrowsecurity,'rls_forced',relforcerowsecurity,'estimated_rows',reltuples::bigint)
    order by schema_name,relname) from app_relations),'[]'::jsonb),
  'constraints',coalesce((select jsonb_agg(jsonb_build_object('schema',r.schema_name,'table',r.relname,'name',k.conname,
    'kind',k.contype,'validated',k.convalidated,'definition_md5',md5(pg_catalog.pg_get_constraintdef(k.oid)))
    order by r.schema_name,r.relname,k.conname) from app_relations r join pg_catalog.pg_constraint k on k.conrelid=r.oid),'[]'::jsonb),
  'indexes',coalesce((select jsonb_agg(jsonb_build_object('schema',r.schema_name,'table',r.relname,'name',i.relname,
    'valid',x.indisvalid,'ready',x.indisready,'unique',x.indisunique,'primary',x.indisprimary,
    'definition_md5',md5(pg_catalog.pg_get_indexdef(i.oid))) order by r.schema_name,r.relname,i.relname)
    from app_relations r join pg_catalog.pg_index x on x.indrelid=r.oid join pg_catalog.pg_class i on i.oid=x.indexrelid),'[]'::jsonb),
  'triggers',coalesce((select jsonb_agg(jsonb_build_object('schema',r.schema_name,'table',r.relname,'name',t.tgname,
    'enabled',t.tgenabled,'function_schema',fn.nspname,'function_name',p.proname)
    order by r.schema_name,r.relname,t.tgname) from app_relations r join pg_catalog.pg_trigger t on t.tgrelid=r.oid
    join pg_catalog.pg_proc p on p.oid=t.tgfoid join pg_catalog.pg_namespace fn on fn.oid=p.pronamespace where not t.tgisinternal),'[]'::jsonb)
)) as audit_report;
