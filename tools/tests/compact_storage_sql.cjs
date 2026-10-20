const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const sql = file => fs.readFileSync(path.join(root, file), 'utf8');
const compact = sql('supabase/migrations/016_compact_storage.sql');
const user = '00000000-0000-0000-0000-000000000001';

(async () => {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  for (const name of fs.readdirSync(path.join(root, 'supabase/migrations')).filter(n => /^00\d_|^01[0-5]_/.test(n)).sort())
    await db.exec(sql('supabase/migrations/' + name));
  await db.query('insert into auth.users values ($1)', [user]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  const keys = (await db.query('select question_key from quiz_private.questions order by slot limit 3')).rows.map(r => r.question_key);
  const call = async (dev, key, answer, include = true) => (await db.query(
    `select public.quiz_answer${dev ? '_dev' : ''}($1,$2,$3) as r`, [key, answer, include])).rows[0].r;
  const board = async (dev, stars) => (await db.query(
    `select public.leaderboard_sync${dev ? '_dev' : ''}($1,true,'ru',true,'SavedName',2,5) as r`, [stars])).rows[0].r;
  const boards = [];
  for (const dev of [false, true]) {
    await db.exec('set role authenticated');
    assert.deepEqual((await call(dev, keys[0], 2)).counts, [0, 0, 1, 0]);
    await call(dev, keys[1], -2, false);
    boards.push(await board(dev, 2000000000));
    await db.exec('reset role');
  }
  async function snapshot(compacted) {
    const data = {};
    for (const schema of ['quiz_private', 'quiz_dev_private']) {
      const key = compacted ? "language || ':' || question_id::text || ':' || encode(revision_hash,'hex')" : 'question_key';
      data[schema] = (await db.query(`select slot,${key} as key,counts from ${schema}.questions order by slot`)).rows;
      data[schema + '.seen'] = (await db.query(`select user_id,encode(seen,'hex') as seen from ${schema}.players order by user_id`)).rows;
      data[schema + '.sequence'] = (await db.query(`select last_value,is_called from ${schema}.questions_slot_seq`)).rows;
    }
    for (const schema of ['leaderboard_private', 'leaderboard_dev_private']) {
      for (const table of ['players', 'profiles', 'fillers'])
        data[schema + '.' + table] = (await db.query(`select to_jsonb(t) as row from ${schema}.${table} t order by to_jsonb(t)::text`)).rows;
    }
    return data;
  }
  // An unexpected legacy identity must abort the entire conversion, including numeric types.
  await db.exec("insert into quiz_dev_private.questions(question_key) values ('invalid-legacy-key')");
  await assert.rejects(() => db.exec(compact), /Invalid legacy quiz key/);
  await db.exec('rollback');
  assert.equal((await db.query("select data_type from information_schema.columns where table_schema='leaderboard_private' and table_name='players' and column_name='stars'")).rows[0].data_type, 'bigint');
  await db.exec("delete from quiz_dev_private.questions where question_key='invalid-legacy-key'");
  const before = await snapshot(false);
  const bytesBefore = (await db.query("select pg_total_relation_size('quiz_private.questions') as bytes")).rows[0].bytes;
  await db.exec(compact);
  assert.deepEqual(await snapshot(true), before, 'Migration preserves all identities, sequences, data and seen bits');
  const bytesAfter = (await db.query("select pg_total_relation_size('quiz_private.questions') as bytes")).rows[0].bytes;
  assert.ok(bytesAfter < bytesBefore, 'Physical quiz table and indexes shrink after conversion');
  await db.exec(compact);
  assert.deepEqual(await snapshot(true), before, 'Repeat application preserves data');
  const types = (await db.query(`select table_schema,table_name,column_name,data_type from information_schema.columns
    where table_schema in ('leaderboard_private','leaderboard_dev_private') and column_name in ('stars','character_id','frame_id')`)).rows;
  assert.equal(types.length, 10);
  assert.ok(types.every(r => r.data_type === (r.column_name === 'stars' ? 'integer' : 'smallint')));
  assert.equal((await db.query("select count(*)::int as n from quiz_private.questions where octet_length(revision_hash)<>32")).rows[0].n, 0);
  assert.equal((await db.query("select count(*)::int as n from information_schema.columns where table_schema in ('quiz_private','quiz_dev_private') and column_name='question_key'")).rows[0].n, 0);
  for (const dev of [false, true]) {
    const schema = dev ? 'quiz_dev_private' : 'quiz_private';
    await db.exec('set role authenticated');
    assert.deepEqual(await board(dev, 1), boards[dev ? 1 : 0], 'Published leaderboard API and ranking unchanged');
    await assert.rejects(() => board(dev, 2000000001));
    await assert.rejects(() => db.query(`select public.leaderboard_sync${dev ? '_dev' : ''}(1,true,'en',false,'SavedName',40000,1)`), e => e.code === '22023');
    assert.deepEqual(await call(dev, keys[0], 0), {ok: true, counts: [0, 0, 1, 0], already_answered: true});
    assert.deepEqual(await call(dev, keys[1], 0), {ok: true, counts: [0, 0, 0, 0], already_answered: true});
    assert.equal((await call(dev, keys[2], -1)).already_answered, false);
    assert.deepEqual(await call(dev, keys[2], 3, false), {ok: true});
    assert.deepEqual((await call(dev, keys[2], 0)).counts, [0, 0, 0, 1]);
    for (const key of [null, 'unknown', 'ru:0:' + 'a'.repeat(64), 'ru:2147483648:' + 'a'.repeat(64), 'en:' + '9'.repeat(50) + ':' + 'a'.repeat(64), keys[0] + ':extra', 'ru:1:xyz'])
      await assert.rejects(() => call(dev, key, 0), e => e.code === '22023');
    await assert.rejects(() => call(dev, keys[0], 4));
    await assert.rejects(() => db.query(`select * from ${schema}.questions`));
    await db.exec('reset role');
    await db.exec('set role anon');
    await assert.rejects(() => call(dev, keys[0], -1));
    await assert.rejects(() => board(dev, 1));
    await db.exec('reset role');
  }
  const populated = await snapshot(true);
  const catalog = sql('supabase/quiz_statistics_catalog.sql');
  const sync = sql('supabase/quiz_statistics_dev_sync.sql');
  await db.exec(catalog); await db.exec(catalog);
  await db.exec(sync); await db.exec(sync);
  assert.deepEqual(await snapshot(true), populated, 'Catalog refresh does not reallocate slots or copy votes');
  // A new revision of an existing question gets a new slot and independent first attempt.
  const [language, id] = keys[0].split(':');
  const hash = 'ab'.repeat(32);
  await db.query('insert into quiz_private.questions(language,question_id,revision_hash,counts) values ($1,$2,decode($3,\'hex\'),array[9,8,7,6]::bigint[])', [language, +id, hash]);
  await db.exec(sync);
  await db.exec('set role authenticated');
  assert.deepEqual(await call(true, `${language}:${id}:${hash}`, -1), {ok: true, counts: [0, 0, 0, 0], already_answered: false});
  assert.deepEqual((await call(false, keys[0], 0)).counts, [0, 0, 1, 0]);
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub','',false)");
  await db.exec('set role authenticated');
  await assert.rejects(() => call(false, keys[0], -1));
  await db.exec('reset role');
  await db.query('delete from auth.users where id=$1', [user]);
  assert.equal((await db.query('select count(*)::int as n from quiz_private.players')).rows[0].n, 0);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.profiles')).rows[0].n, 0);
  console.log(`COMPACT_STORAGE SQL passed: transactional rollback, repeat migration, identities/sequences/votes/seen preserved, legacy RPC, validation, permissions, dev/prod, catalog sync, cascades; quiz bytes ${bytesBefore} -> ${bytesAfter}`);
  await db.close();
})().catch(error => { console.error(error); process.exit(1); });
