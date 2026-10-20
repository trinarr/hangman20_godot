-- OPTIONAL PRIVATE CODE REVIEW. No RPC is executed and no application rows are read.
-- Exported function source could contain credentials hardcoded manually on the server.
-- Review this export locally before sharing it. Default reports 01-04 omit source.
with relations as (
  select c.oid,c.relname,c.relkind,n.nspname from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private')
    and c.relkind in ('r','p','v','m')
)
select jsonb_pretty(jsonb_build_object(
  'report','hangman_rpc_source_v1','observed_at',statement_timestamp(),'sql_role',current_user,
  'functions',coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,
    'arg_types',pg_catalog.oidvectortypes(p.proargtypes),'body_md5',md5(p.prosrc),
    'definition',pg_catalog.pg_get_functiondef(p.oid)) order by p.proname,p.oid),'[]'::jsonb),
  'policies',coalesce((select jsonb_agg(jsonb_build_object('schema',schemaname,'table',tablename,'name',policyname,
    'using',qual,'check',with_check) order by schemaname,tablename,policyname) from pg_catalog.pg_policies
    where schemaname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private')),'[]'::jsonb),
  'constraints',coalesce((select jsonb_agg(jsonb_build_object('schema',r.nspname,'table',r.relname,'name',k.conname,
    'definition',pg_catalog.pg_get_constraintdef(k.oid)) order by r.nspname,r.relname,k.conname)
    from relations r join pg_catalog.pg_constraint k on k.conrelid=r.oid),'[]'::jsonb),
  'indexes',coalesce((select jsonb_agg(jsonb_build_object('schema',r.nspname,'table',r.relname,'name',c.relname,
    'definition',pg_catalog.pg_get_indexdef(c.oid)) order by r.nspname,r.relname,c.relname)
    from relations r join pg_catalog.pg_index i on i.indrelid=r.oid join pg_catalog.pg_class c on c.oid=i.indexrelid),'[]'::jsonb),
  'column_defaults',coalesce((select jsonb_agg(jsonb_build_object('schema',r.nspname,'table',r.relname,'column',a.attname,
    'expression',pg_catalog.pg_get_expr(d.adbin,d.adrelid)) order by r.nspname,r.relname,a.attnum)
    from relations r join pg_catalog.pg_attribute a on a.attrelid=r.oid and a.attnum>0 and not a.attisdropped
    join pg_catalog.pg_attrdef d on d.adrelid=r.oid and d.adnum=a.attnum),'[]'::jsonb),
  'views',coalesce((select jsonb_agg(jsonb_build_object('schema',r.nspname,'name',r.relname,
    'definition',pg_catalog.pg_get_viewdef(r.oid,true)) order by r.nspname,r.relname)
    from relations r where r.relkind in ('v','m')),'[]'::jsonb)
)) as audit_report
from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('leaderboard_sync','leaderboard_sync_dev','quiz_answer','quiz_answer_dev','quiz_answers','quiz_answers_dev','tournament_profiles','tournament_profiles_dev') and p.prokind='f';
