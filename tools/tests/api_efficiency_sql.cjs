const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const migration = read('supabase/migrations/017_api_efficiency.sql');
const user = '00000000-0000-0000-0000-000000000001';
const other = '00000000-0000-0000-0000-000000000002';
(async () => {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create role service_role;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  for (const name of fs.readdirSync(path.join(root, 'supabase/migrations')).filter(n => /^(00\d|01[0-6])_/.test(n)).sort())
    await db.exec(read('supabase/migrations/' + name));
  await db.query('insert into auth.users values ($1),($2)', [user, other]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  const before = [];
  for (const suffix of ['', '_dev'])
    before.push((await db.query(`select public.leaderboard_sync${suffix}(90,true,'ru',true,'SavedName',2,5) as r`)).rows[0].r);
  await db.exec(migration);
  for (const [i, suffix] of ['', '_dev'].entries()) {
    const schema = suffix ? 'leaderboard_dev_private' : 'leaderboard_private';
    const population = async () => {
      const row = (await db.query(`select (select total from ${schema}.population where singleton) as stored,
        (select count(*) from ${schema}.players where stars>0) as actual`)).rows[0];
      assert.equal(row.stored, row.actual); return +row.stored;
    };
    assert.equal(await population(), 1);
    assert.deepEqual((await db.query(`select public.leaderboard_sync${suffix}(null,true,'ru',true) as r`)).rows[0].r, before[i]);
    await db.query(`insert into ${schema}.players(user_id,stars) values ($1,0)`, [other]);
    assert.equal(await population(), 1);
    await db.query(`update ${schema}.players set stars=100 where user_id=$1`, [other]);
    assert.equal(await population(), 2);
    await db.query(`update ${schema}.players set stars=101 where user_id=$1`, [other]);
    assert.equal(await population(), 2);
    await db.query(`update ${schema}.players set stars=0 where user_id=$1`, [other]);
    assert.equal(await population(), 1);
    await db.exec(`begin; truncate ${schema}.players;`);
    assert.equal(await population(), 0);
    await db.exec('rollback');
    assert.equal(await population(), 1);
    await db.exec(`begin; delete from ${schema}.players;`);
    assert.equal(await population(), 0);
    await db.exec('rollback');
    assert.equal(await population(), 1);
    await db.exec('set role authenticated');
    await assert.rejects(() => db.query(`select * from ${schema}.population`));
    await assert.rejects(() => db.exec(`update ${schema}.population set total=999`));
    await db.exec('reset role');
    const source = (await db.query(`select prosrc from pg_proc where oid='public.leaderboard_sync${suffix}(bigint,boolean,text,boolean,text,integer,integer)'::regprocedure`)).rows[0].prosrc;
    assert.ok(source.includes(`${schema}.population`));
    assert.ok(!source.includes(`count(*) as total from ${schema}.players`));
  }
  const keys = (await db.query("select language||':'||question_id||':'||encode(revision_hash,'hex') as key from quiz_private.questions order by slot limit 3")).rows.map(r => r.key);
  const unknown = 'en:2147483647:' + 'f'.repeat(64);
  for (const suffix of ['', '_dev']) {
    const schema = suffix ? 'quiz_dev_private' : 'quiz_private';
    const batch = async entries => (await db.query(`select public.quiz_answers${suffix}($1::jsonb) as r`, [JSON.stringify(entries)])).rows[0].r;
    const single = async (key, answer = -1) => (await db.query(`select public.quiz_answer${suffix}($1,$2,true) as r`, [key, answer])).rows[0].r;
    await db.exec('set role authenticated');
    assert.deepEqual(await single(keys[0]), {ok: true, counts: [0, 0, 0, 0], already_answered: false});
    await assert.rejects(() => single(unknown), e => e.code === '22023');
    await db.exec('reset role');
    assert.equal((await db.query(`select count(*)::int as n from ${schema}.players`)).rows[0].n, 0, 'Prefetch is read-only');
    await db.exec('set role authenticated');
    const entries = [
      {p_key: keys[0], p_answer: 2}, {p_key: unknown, p_answer: 0},
      {p_key: keys[1], p_answer: -2, p_include_counts: false},
      {p_key: keys[0], p_answer: 0}, {p_key: keys[2], p_answer: -1}
    ];
    const result = await batch(entries);
    assert.equal(result.ok, true); assert.equal(result.results.length, 5);
    assert.deepEqual(result.results.map(r => r.ok), [true, false, true, true, true]);
    assert.equal(result.results[1].code, '22023');
    assert.deepEqual(result.results[0].counts, [0, 0, 1, 0]);
    assert.deepEqual(result.results[3].counts, [0, 0, 1, 0], 'Duplicate in batch counts only once');
    assert.equal(result.results[2].counts, undefined);
    assert.equal(result.results[4].already_answered, false);
    assert.deepEqual((await single(keys[1], 0)).counts, [0, 0, 0, 0], 'Hinted first attempt remains consumed');
    await batch(entries);
    assert.deepEqual((await single(keys[0])).counts, [0, 0, 1, 0], 'Lost batch acknowledgement can be retried');
    for (const invalid of [null, {}, [], Array(21).fill(entries[0])])
      await assert.rejects(() => batch(invalid), e => e.code === '22023');
    const invalidItems = [null, {}, {p_key: keys[0], p_answer: '0'}, {p_key: keys[0], p_answer: 4}, {p_key: keys[0], p_answer: 0, p_include_counts: null}];
    assert.ok((await batch(invalidItems)).results.every(r => r.ok === false));
    assert.equal((await batch(Array(20).fill(entries[0]))).results.length, 20);
    const decimalPayload = JSON.stringify([{p_key: keys[0], p_answer: 1}]).replace('"p_answer":1', '"p_answer":1.0');
    assert.equal((await db.query(`select public.quiz_answers${suffix}($1::jsonb) as r`, [decimalPayload])).rows[0].r.results[0].ok, true);
    await db.exec('reset role');
    await db.exec('set role anon');
    await assert.rejects(() => batch(entries));
    await db.exec('reset role');
  }
  await db.exec(migration);
  assert.deepEqual((await db.query('select public.leaderboard_sync(null,true,\'ru\',true) as r')).rows[0].r, before[0], 'Repeat migration keeps board unchanged');
  await db.query('delete from auth.users where id=$1', [user]);
  for (const schema of ['leaderboard_private', 'leaderboard_dev_private'])
    assert.equal(+(await db.query(`select total from ${schema}.population`)).rows[0].total, 0, 'Auth cascade maintains counter');
  await db.query("select set_config('request.jwt.claim.sub','',false)");
  await db.exec('set role authenticated');
  await assert.rejects(() => db.query('select public.quiz_answers(\'[]\'::jsonb)'));
  await db.close();
  console.log('API_EFFICIENCY SQL passed: exact counters, zero/positive transitions, rollback/truncate/cascade, repeat migration, unchanged leaderboard, read-only prefetch, batch limits/partial errors/retries/dedup, rights and dev/prod');
})().catch(error => { console.error(error); process.exit(1); });
