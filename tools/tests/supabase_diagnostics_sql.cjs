const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname,'../..');
const folder = path.join(root,'supabase/diagnostics');
const files = fs.readdirSync(folder).filter(n=>n.endsWith('.sql')).sort();
const privateMarkers = ['PrivateName', 'private-email@example.invalid', 'private-refresh-token', 'private-password'];
async function setup(db, partial=false) {
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth; create table auth.users(id uuid primary key,email text,encrypted_password text);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  for (const name of fs.readdirSync(path.join(root,'supabase/migrations')).filter(n=>/^\d{3}_/.test(n)).sort()) {
    if (partial && /^(013|015)_/.test(name)) continue;
    await db.exec(fs.readFileSync(path.join(root,'supabase/migrations',name),'utf8'));
  }
  await db.exec(`create schema supabase_migrations;
    create table supabase_migrations.schema_migrations(version text primary key,name text,statements text[]);
    insert into supabase_migrations.schema_migrations values ('001','private-refresh-token',array['private-password']);
    insert into auth.users values ('00000000-0000-0000-0000-000000000001','private-email@example.invalid','private-password');
    insert into leaderboard_private.players(user_id,stars) values ('00000000-0000-0000-0000-000000000001',235);
    insert into leaderboard_private.profiles(user_id,nickname,character_id,frame_id)
      values ('00000000-0000-0000-0000-000000000001','PrivateName',2,5);
    insert into quiz_private.players(user_id,seen) values ('00000000-0000-0000-0000-000000000001',decode('0102','hex'));
    update quiz_private.questions set counts=array[1,2,3,4] where slot=1;`);
}
async function snapshot(db) {
  const tables=(await db.query(`select n.nspname,c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname in ('leaderboard_private','leaderboard_dev_private','quiz_private','quiz_dev_private','auth','supabase_migrations') and c.relkind='r'
    order by n.nspname,c.relname`)).rows;
  const result={};
  for (const {nspname,relname} of tables)
    result[nspname+'.'+relname]=(await db.query(`select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]'::jsonb) as data from "${nspname}"."${relname}" t`)).rows[0].data;
  result.functions=(await db.query(`select p.proname,pg_get_functiondef(p.oid) as source from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('leaderboard_sync','leaderboard_sync_dev','quiz_answer','quiz_answer_dev') order by p.proname`)).rows;
  return result;
}
async function collect(db, role=null) {
  const result={};
  await db.exec('begin transaction read only');
  try {
    await db.exec("set local statement_timeout='15s'");
    if (role) await db.exec(`set local role ${role}`);
    for (const file of files) {
      const sql=fs.readFileSync(path.join(folder,file),'utf8');
      assert.match(sql.replace(/^\s*--[^\n]*(?:\n|$)/gm,''),/^\s*(with|select)\b/i);
      let rows;
      try { rows=(await db.query(sql)).rows; }
      catch(error) { error.diagnosticFile=file; throw error; }
      assert.equal(rows.length,1,file);
      const report=JSON.parse(rows[0].audit_report);
      assert.ok(report.report && report.observed_at,file);
      const serialized=JSON.stringify(report);
      for (const marker of privateMarkers) assert.ok(!serialized.includes(marker),file+' leaked '+marker);
      result[file]=report;
    }
    assert.equal((await db.query("select current_setting('transaction_read_only') as value")).rows[0].value,'on');
  } finally { await db.exec('rollback'); }
  return result;
}
function table(report,schema,name) {
  return report['03_data_aggregates.sql'].tables.find(r=>r.schema===schema&&r.table===name).result;
}
(async()=>{
  assert.equal(files.length,5);
  for (const partial of [false,true]) {
    const db=new PGlite(); await setup(db,partial);
    const before=await snapshot(db);
    const report=await collect(db);
    assert.deepEqual(await snapshot(db),before,'Diagnostics changed data or RPC definitions');
    assert.ok(report['01_schema.sql'].rpc_checks.every(r=>r.status==='OK'));
    assert.deepEqual(report['01_schema.sql'].migration_history,{status:'OK',versions:['001']});
    const columns=report['01_schema.sql'].column_checks;
    if (partial) {
      assert.equal(columns.filter(r=>r.status==='MISSING_COLUMN').length,4);
      assert.equal(table(report,'leaderboard_dev_private','fillers').metrics.invalid_or_missing_character_id,200);
    } else {
      assert.ok(columns.every(r=>r.status==='OK'));
      assert.equal(table(report,'leaderboard_dev_private','fillers').metrics.invalid_or_missing_character_id,0);
    }
    assert.equal(table(report,'leaderboard_private','players').metrics.max_stars,235);
    assert.equal(table(report,'leaderboard_private','profiles').metrics.rows,1);
    assert.equal(table(report,'quiz_private','questions').metrics.total_recorded_votes,10);
    assert.equal(table(report,'quiz_private','players').metrics.maximum_seen_bytes,2);
    const limited=await collect(db,'authenticated');
    assert.ok(limited['03_data_aggregates.sql'].tables.every(r=>r.result.status==='INSUFFICIENT_PRIVILEGE'));
    await db.exec('grant usage on schema quiz_dev_private to authenticated; grant select on quiz_dev_private.questions to authenticated;');
    const filtered=await collect(db,'authenticated');
    assert.equal(table(filtered,'quiz_dev_private','questions').status,'FILTERED_BY_RLS');
    assert.equal(table(filtered,'quiz_dev_private','questions').metrics.rows,0);
    if (!partial) {
      await db.exec("update quiz_private.questions set counts=array[-1,null]::bigint[] where slot=1");
      const malformed=await collect(db);
      assert.equal(table(malformed,'quiz_private','questions').metrics.invalid_counts_shape,1);
      assert.equal(table(malformed,'quiz_private','questions').metrics.invalid_count_values,1);
    }
    await db.close();
  }
  const empty=new PGlite(); const report=await collect(empty);
  assert.ok(report['01_schema.sql'].column_checks.every(r=>r.status==='MISSING_TABLE'));
  assert.ok(report['01_schema.sql'].rpc_checks.every(r=>r.status==='MISSING_RPC'));
  assert.ok(report['03_data_aggregates.sql'].tables.every(r=>r.result.status==='MISSING_TABLE'));
  assert.deepEqual(report['05_rpc_source_private.sql'].functions,[]);
  await empty.close();
  console.log('SUPABASE_DIAGNOSTICS SQL passed: all five queries under READ ONLY, healthy/partial/empty databases, restricted roles, RLS visibility, aggregate checks, malformed arrays, no fixture secrets/user records exported, unchanged data and RPCs');
})().catch(error=>{console.error(error.diagnosticFile||'',error.code||'',error.message);process.exit(1);});
