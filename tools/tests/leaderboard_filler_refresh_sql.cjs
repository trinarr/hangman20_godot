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
  for (const name of fs.readdirSync(root+'/supabase/migrations').filter(n=>/^(00[5-9]|01[01])_/.test(n)).sort())
    await db.exec(fs.readFileSync(root+'/supabase/migrations/'+name,'utf8'));
  const user = '00000000-0000-0000-0000-000000000001';
  await db.query('insert into auth.users values ($1)', [user]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  const call = async (dev, language, stars = null) => (await db.query(
    `select public.leaderboard_sync${dev?'_dev':''}($1,true,$2,true) as r`, [stars,language])).rows[0].r;
  const snapshots = {};
  for (const dev of [false,true]) {
    await call(dev,'ru',90);
    snapshots[dev] = {};
    for (const language of ['ru','en']) snapshots[dev][language] = await call(dev,language);
  }
  const sql = fs.readFileSync(root+'/supabase/migrations/012_leaderboard_filler_refresh.sql','utf8');
  const seed = JSON.parse(fs.readFileSync(root+'/supabase/seeds/leaderboard_filler_nicknames_v3.json','utf8'));
  for (let repeat=0; repeat<2; repeat++) {
    await db.exec(sql);
    for (const dev of [false,true]) {
      const schema = dev?'leaderboard_dev_private':'leaderboard_private';
      const rows = (await db.query(`select pool,slot,nickname,style from ${schema}.fillers order by pool,slot`)).rows;
      assert.equal(rows.length,200);
      assert.equal(new Set(rows.map(r=>r.nickname.toLocaleLowerCase())).size,200);
      for (const row of rows) {
        assert.equal(row.nickname,seed[row.pool][row.slot-1]);
        assert.equal(row.style,seed.slang_slots[row.pool].includes(row.slot)?'slang':'casual');
        assert.ok([...row.nickname].length>=2 && [...row.nickname].length<=18);
      }
      for (const invalid of ['A','X'.repeat(19),' Space','With Space','Bad\nName','Bad\tName'])
        await assert.rejects(()=>db.query(`update ${schema}.fillers set nickname=$1 where pool='cis' and slot=1`,[invalid]));
      await db.exec('set role authenticated');
      for (const language of ['ru','en']) {
        const before = snapshots[dev][language];
        const after = await call(dev,language);
        assert.deepEqual(after.me,before.me);
        assert.deepEqual(after.top,before.top);
        assert.equal(after.total_players,before.total_players);
        assert.equal(after.fillers.filter(r=>r.player_id.startsWith('filler:cis:')).length,language==='ru'?60:20);
        assert.deepEqual(after.fillers.map(({nickname,...r})=>r),before.fillers.map(({nickname,...r})=>r));
        assert.ok(after.fillers.every((r,i)=>r.nickname!==before.fillers[i].nickname));
      }
      await assert.rejects(()=>db.query(`select * from ${schema}.fillers`));
      await db.exec('reset role');
      await db.exec('set role anon');
      await assert.rejects(()=>db.query(`update ${schema}.fillers set nickname='Injected'`));
      await db.exec('reset role');
    }
  }
  const appearanceSql = fs.readFileSync(root+'/supabase/migrations/013_leaderboard_filler_appearance.sql','utf8');
  const profiles = JSON.parse(fs.readFileSync(root+'/supabase/seeds/leaderboard_filler_nicknames_v4.json','utf8'));
  const beforeAppearance = {};
  for (const dev of [false,true]) {
    beforeAppearance[dev] = {};
    for (const language of ['ru','en']) beforeAppearance[dev][language] = await call(dev,language);
  }
  for (let repeat=0;repeat<2;repeat++) {
    await db.exec(appearanceSql);
    for (const dev of [false,true]) {
      const schema = dev?'leaderboard_dev_private':'leaderboard_private';
      const rows = (await db.query(`select pool,slot,nickname,character_id,frame_id from ${schema}.fillers order by pool,slot`)).rows;
      assert.equal(rows.length,200);
      for (const {pool,slot,...profile} of rows) assert.deepEqual(profile,profiles[pool][slot-1]);
      for (const [character,frame] of [[0,1],[3,1],[1,0],[1,6],[null,1],[1,null]])
        await assert.rejects(()=>db.query(`update ${schema}.fillers set character_id=$1,frame_id=$2 where pool='cis' and slot=1`,[character,frame]));
      await db.exec('set role authenticated');
      for (const language of ['ru','en']) assert.deepEqual(await call(dev,language),beforeAppearance[dev][language]);
      await assert.rejects(()=>db.query(`select character_id,frame_id from ${schema}.fillers`));
      await db.exec('reset role');
      // Prove RPC reads the stored profile rather than recomputing a hash.
      const chosen = beforeAppearance[dev].ru.fillers[0];
      const [,pool,slot] = chosen.player_id.split(':');
      const character = 3-chosen.character_id;
      const frame = chosen.frame_id%5+1;
      await db.query(`update ${schema}.fillers set character_id=$1,frame_id=$2 where pool=$3 and slot=$4`,[character,frame,pool,Number(slot)]);
      const changed = (await call(dev,'ru')).fillers.find(r=>r.player_id===chosen.player_id);
      assert.equal(changed.character_id,character); assert.equal(changed.frame_id,frame);
    }
  }
  await db.close();
  console.log('FILLER_REFRESH SQL passed: 200 names and stored appearances per environment, constraints, RPC table reads, styles, language quotas, unchanged IDs/scores/profiles, permissions and repeat application');
})().catch(error=>{console.error(error);process.exit(1);});
