const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
(async () => {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  for (const name of fs.readdirSync(root+'/supabase/migrations').filter(n=>/^(00[5-9]|01[0-4])_/.test(n)).sort())
    await db.exec(fs.readFileSync(root+'/supabase/migrations/'+name,'utf8'));
  await db.exec(`insert into auth.users select md5('rank-boundary:'||n)::uuid from generate_series(1,10000) n;`);
  const migration = fs.readFileSync(root+'/supabase/migrations/014_leaderboard_rank_boundary.sql','utf8');
  assert.ok(!migration.includes('ceil('));
  for (const dev of [false,true]) {
    const schema = dev?'leaderboard_dev_private':'leaderboard_private';
    const rpc = `public.leaderboard_sync${dev?'_dev':''}`;
    await db.exec(`insert into ${schema}.players(user_id,stars)
      select md5('rank-boundary:'||n)::uuid,10001-n from generate_series(1,10000) n;`);
    for (let repeat=0;repeat<2;repeat++) {
      await db.exec(migration);
      for (const rank of [1,2,3,99,100,101,9999,10000]) {
        const user=(await db.query("select md5('rank-boundary:'||$1)::uuid as id",[rank])).rows[0].id;
        await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user]);
        await db.exec('set role authenticated');
        for (const includeTop of [false,true]) {
          const result=(await db.query(`select ${rpc}(null,$1,'en',false) as r`,[includeTop])).rows[0].r;
          assert.equal(result.me.rank,rank<=100?rank:null);
          assert.equal(result.me.top_percent,rank<=100?null:100); // Reserved legacy field.
          assert.equal(result.me.stars,10001-rank);
          assert.equal(result.total_players,10000);
          assert.equal(result.protocol_version,2);
          if (includeTop) {
            assert.equal(result.top.length,100);
            assert.equal(result.top[99].rank,100);
          }
        }
        await assert.rejects(()=>db.query(`select * from ${schema}.players`));
        await db.exec('reset role');
      }
      await db.exec('set role anon');
      await assert.rejects(()=>db.query(`select ${rpc}()`));
      await db.exec('reset role');
    }
    // Equal scores retain the existing reached_at/player_id ordering.
    await db.exec(`update ${schema}.players set stars=100,reached_at='2026-01-01';`);
    const ordered=(await db.query(`select user_id from ${schema}.players order by reached_at,player_id limit 101`)).rows;
    for (const index of [0,99,100]) {
      await db.query("select set_config('request.jwt.claim.sub',$1,false)",[ordered[index].user_id]);
      const result=(await db.query(`select ${rpc}(null,false,'ru',false) as r`)).rows[0].r;
      assert.equal(result.me.rank,index<100?index+1:null);
    }
  }
  await db.close();
  console.log('RANK_BOUNDARY SQL passed: top-100 boundaries, 10000 players, ties, dev/prod, legacy contract, permissions, repeat application');
})().catch(error=>{console.error(error);process.exit(1);});
