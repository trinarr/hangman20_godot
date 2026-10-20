-- Metadata and cumulative statistics only. No active SQL, client IPs or session tokens.
-- This is a current/cumulative snapshot, not an error log or a historical SLA check.
with app_tables as (
  select c.oid,n.nspname,c.relname from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid=c.relnamespace
  where n.nspname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private') and c.relkind in ('r','p','m')
)
select jsonb_pretty(jsonb_build_object(
  'report','hangman_health_v1','observed_at',statement_timestamp(),'sql_role',current_user,
  'database',current_database(),'postgres_version',current_setting('server_version'),
  'settings',jsonb_build_object('timezone',current_setting('TimeZone'),'max_connections',current_setting('max_connections'),
    'statement_timeout',current_setting('statement_timeout'),'lock_timeout',current_setting('lock_timeout'),
    'default_transaction_read_only',current_setting('default_transaction_read_only'),
    'transaction_read_only',current_setting('transaction_read_only'),'row_security',current_setting('row_security'),
    'pgrst_db_schemas',current_setting('pgrst.db_schemas',true)),
  'database_bytes',pg_catalog.pg_database_size(current_database()),
  'database_stats',(select jsonb_build_object('stats_reset',stats_reset,'commits',xact_commit,'rollbacks',xact_rollback,
    'deadlocks',deadlocks,'temp_files',temp_files,'temp_bytes',temp_bytes,'blocks_read',blks_read,'blocks_hit',blks_hit)
    from pg_catalog.pg_stat_database where datname=current_database()),
  'connection_counts',coalesce((select jsonb_agg(jsonb_build_object('state',state,'count',total)) from
    (select coalesce(state,'NOT_VISIBLE_OR_BACKGROUND') as state,count(*) as total from pg_catalog.pg_stat_activity
      where datname=current_database() group by coalesce(state,'NOT_VISIBLE_OR_BACKGROUND')) c),'[]'::jsonb),
  'waiting_lock_count',(select count(*) from pg_catalog.pg_locks where not granted and database=(select oid from pg_catalog.pg_database where datname=current_database())),
  'extensions',(select jsonb_agg(jsonb_build_object('name',e.extname,'version',e.extversion,'schema',n.nspname) order by e.extname)
    from pg_catalog.pg_extension e join pg_catalog.pg_namespace n on n.oid=e.extnamespace),
  'table_stats',coalesce((select jsonb_agg(jsonb_build_object('schema',t.nspname,'table',t.relname,
    'total_bytes',pg_catalog.pg_total_relation_size(t.oid),'estimated_live_rows',s.n_live_tup,'estimated_dead_rows',s.n_dead_tup,
    'seq_scans',s.seq_scan,'index_scans',s.idx_scan,'last_analyze',s.last_analyze,'last_autoanalyze',s.last_autoanalyze,
    'last_vacuum',s.last_vacuum,'last_autovacuum',s.last_autovacuum) order by t.nspname,t.relname)
    from app_tables t left join pg_catalog.pg_stat_user_tables s on s.relid=t.oid),'[]'::jsonb),
  'replication_publications',coalesce((select jsonb_agg(jsonb_build_object('publication',pubname,'schema',schemaname,'table',tablename)
    order by pubname,schemaname,tablename) from pg_catalog.pg_publication_tables
    where schemaname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private')),'[]'::jsonb)
)) as audit_report;
