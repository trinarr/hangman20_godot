-- Effective privileges and security metadata. No passwords, JWTs or user rows.
-- Policy expressions are fingerprinted; inspect their source privately if needed.
with
roles as (select oid,rolname,rolsuper,rolbypassrls,rolcanlogin from pg_catalog.pg_roles where rolname in ('anon','authenticated','service_role')),
schemas as (select oid,nspname from pg_catalog.pg_namespace where nspname in ('public','leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private')),
tables as (select c.*,n.nspname from pg_catalog.pg_class c join schemas n on n.oid=c.relnamespace where c.relkind in ('r','p','v','m','f')),
functions as (
  select p.*,n.nspname from pg_catalog.pg_proc p join schemas n on n.oid=p.pronamespace
  where p.prokind='f' and not exists(select 1 from pg_catalog.pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
)
select jsonb_pretty(jsonb_build_object(
  'report','hangman_access_v1','observed_at',statement_timestamp(),'sql_role',current_user,
  'roles',(select jsonb_agg(jsonb_build_object('name',rolname,'superuser',rolsuper,'bypass_rls',rolbypassrls,'can_login',rolcanlogin) order by rolname) from roles),
  'schema_access',(select jsonb_agg(jsonb_build_object('role',r.rolname,'schema',s.nspname,
    'usage',pg_catalog.has_schema_privilege(r.oid,s.oid,'USAGE'),'create',pg_catalog.has_schema_privilege(r.oid,s.oid,'CREATE'))
    order by s.nspname,r.rolname) from roles r cross join schemas s),
  'table_access',(select jsonb_agg(jsonb_build_object('role',r.rolname,'schema',t.nspname,'table',t.relname,
    'schema_usage',pg_catalog.has_schema_privilege(r.oid,t.relnamespace,'USAGE'),
    'select',pg_catalog.has_table_privilege(r.oid,t.oid,'SELECT'),'insert',pg_catalog.has_table_privilege(r.oid,t.oid,'INSERT'),
    'update',pg_catalog.has_table_privilege(r.oid,t.oid,'UPDATE'),'delete',pg_catalog.has_table_privilege(r.oid,t.oid,'DELETE'),
    'truncate',pg_catalog.has_table_privilege(r.oid,t.oid,'TRUNCATE'),
    'rls_enabled',t.relrowsecurity,'rls_forced',t.relforcerowsecurity)
    order by t.nspname,t.relname,r.rolname) from roles r cross join tables t),
  'function_access',(select jsonb_agg(jsonb_build_object('role',r.rolname,'schema',f.nspname,'function',f.proname,
    'arg_types',pg_catalog.oidvectortypes(f.proargtypes),'execute',pg_catalog.has_function_privilege(r.oid,f.oid,'EXECUTE'),
    'security_definer',f.prosecdef,'owner',pg_catalog.pg_get_userbyid(f.proowner),
    'search_path',(select split_part(setting,'=',2) from unnest(coalesce(f.proconfig,'{}'::text[])) setting where setting like 'search_path=%'),
    'body_md5',md5(f.prosrc)) order by f.nspname,f.proname,f.oid,r.rolname) from roles r cross join functions f),
  'policies',coalesce((select jsonb_agg(jsonb_build_object('schema',schemaname,'table',tablename,'name',policyname,
    'mode',permissive,'roles',roles,'command',cmd,'using_present',qual is not null,'check_present',with_check is not null,
    'using_md5',md5(qual),'check_md5',md5(with_check)) order by schemaname,tablename,policyname)
    from pg_catalog.pg_policies where schemaname in (select nspname from schemas)),'[]'::jsonb),
  'sequence_access',coalesce((select jsonb_agg(jsonb_build_object('role',r.rolname,'schema',s.nspname,'sequence',c.relname,
    'usage',pg_catalog.has_sequence_privilege(r.oid,c.oid,'USAGE'),'select',pg_catalog.has_sequence_privilege(r.oid,c.oid,'SELECT'),
    'update',pg_catalog.has_sequence_privilege(r.oid,c.oid,'UPDATE')) order by s.nspname,c.relname,r.rolname)
    from roles r cross join schemas s join pg_catalog.pg_class c on c.relnamespace=s.oid and c.relkind='S'),'[]'::jsonb)
)) as audit_report;
