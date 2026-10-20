const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const migration = read('supabase/migrations/018_tournament_profiles.sql');
const user = '00000000-0000-0000-0000-000000000001';
(async () => {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create role service_role;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  for (const name of fs.readdirSync(path.join(root, 'supabase/migrations')).filter(n => /^\d{3}_/.test(n) && +n.slice(0, 3) <= 17).sort())
    await db.exec(read('supabase/migrations/' + name));
  await db.exec(`insert into auth.users select ('00000000-0000-0000-0000-'||lpad(g::text,12,'0'))::uuid from generate_series(1,182) g;`);
  for (const schema of ['leaderboard_private', 'leaderboard_dev_private']) {
    await db.exec(`insert into ${schema}.players(player_id,user_id,stars) overriding system value
      select g,('00000000-0000-0000-0000-'||lpad(g::text,12,'0'))::uuid,case when g=181 then 0 else 1000-g end from generate_series(1,181) g;
      insert into ${schema}.profiles(user_id,nickname,character_id,frame_id)
      select ('00000000-0000-0000-0000-'||lpad(g::text,12,'0'))::uuid,'${schema.includes('dev') ? 'Dev' : 'Prod'}'||g,2,5 from generate_series(2,180,2) g;`);
  }
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  await db.exec(migration);
  await db.exec(migration); // idempotent, without rewriting players or profiles
  for (const suffix of ['', '_dev']) {
    const schema = suffix ? 'leaderboard_dev_private' : 'leaderboard_private';
    const rpc = async (language = 'en') => (await db.query(`select public.tournament_profiles${suffix}($1) as r`, [language])).rows[0].r;
    await db.exec('set role anon');
    await assert.rejects(() => rpc(), e => e.code === '42501');
    await db.exec('reset role; set role authenticated');
    await assert.rejects(() => db.query(`select * from ${schema}.players`));
    await assert.rejects(() => db.query(`update ${schema}.profiles set nickname='Changed'`));
    const seen = new Set();
    for (let trial = 0; trial < 25; trial++) {
      const result = await rpc(trial % 2 ? 'ru' : 'en');
      assert.equal(result.ok, true);
      assert.equal(result.protocol_version, 1);
      assert.equal(result.profiles.length, 50);
      assert.equal(new Set(result.profiles.map(p => p.player_id)).size, 50);
      for (const row of result.profiles) {
        assert.deepEqual(Object.keys(row).sort(), ['player_id','nickname','character_id','frame_id','is_me','is_filler'].sort());
        assert.notEqual(row.player_id, '1'); assert.notEqual(row.player_id, '181');
        assert.equal(row.is_me, false); assert.equal(row.is_filler, false);
        if (+row.player_id % 2 === 0) {
          assert.equal(row.nickname, (suffix ? 'Dev' : 'Prod') + row.player_id);
          assert.equal(row.character_id, 2); assert.equal(row.frame_id, 5);
        } else {
          assert.equal(row.nickname, (trial % 2 ? 'Игрок ' : 'Player ') + row.player_id);
          assert.equal(row.character_id, 1); assert.equal(row.frame_id, 4);
        }
        seen.add(+row.player_id);
      }
    }
    assert.ok(seen.size > 100 && [...seen].some(id => id > 100), 'Sampling reaches beyond the top hundred');
    await db.exec('reset role');
    await db.exec('begin');
    await db.query(`delete from ${schema}.players where player_id>4`);
    for (let trial = 0; trial < 10; trial++)
      assert.deepEqual((await rpc()).profiles.map(p => p.player_id), ['2','3','4']);
    await db.query(`delete from ${schema}.players where player_id<>1`);
    assert.deepEqual((await rpc()).profiles, []);
    await db.exec('rollback');
    await db.exec('begin');
    await db.exec(`delete from ${schema}.players where player_id<>1;
      insert into ${schema}.players(player_id,user_id,stars) overriding system value
      values (9223372036854775807,'00000000-0000-0000-0000-000000000182',1);`);
    const largeId = (await rpc()).profiles[0];
    assert.equal(largeId.player_id, '9223372036854775807');
    assert.ok(largeId.nickname.length <= 24);
    await db.exec('rollback');
    await db.exec(`analyze ${schema}.players; set enable_seqscan=off;`);
    const plan = await db.query(`explain select player_id,user_id from ${schema}.players
      where stars>0 and user_id<>'${user}'::uuid and md5(player_id::text)>='8'
      order by md5(player_id::text),player_id limit 50`);
    assert.ok(JSON.stringify(plan.rows).includes('players_tournament_sample_idx'), 'Sampling uses the bounded range index');
    await db.exec('reset enable_seqscan');
    const fn = (await db.query(`select proconfig from pg_proc where oid='public.tournament_profiles${suffix}(text)'::regprocedure`)).rows[0];
    assert.ok(fn.proconfig.includes('search_path=""'));
    await db.query("select set_config('request.jwt.claim.sub','',false)");
    await assert.rejects(() => rpc(), e => e.code === '42501');
    await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
    assert.equal(+(await db.query(`select count(*) as n from ${schema}.players`)).rows[0].n, 181);
  }
  await db.close();
  console.log('TOURNAMENT_PROFILES_SQL passed: dev/prod, all ranks, self exclusion, sparse wrap, public fields, grants, index and reapply');
})().catch(error => { console.error(error); process.exit(1); });
