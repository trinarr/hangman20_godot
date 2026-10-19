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
  const user='00000000-0000-0000-0000-000000000001';
  const other='00000000-0000-0000-0000-000000000002';
  await db.query('insert into auth.users values ($1),($2)',[user,other]);
  const owner=async id=>db.query("select set_config('request.jwt.claim.sub',$1,false)",[id]);
  const call=async(stars=null,nickname='CozyMuffin',character=2,frame=3,dev=false)=>(await db.query(
    `select public.leaderboard_sync${dev?'_dev':''}($1,true,'en',true,$2,$3,$4) as r`,[stars,nickname,character,frame])).rows[0].r;
  for (const dev of [false,true]) {
    const schema=dev?'leaderboard_dev_private':'leaderboard_private';
    await owner(user); await db.exec('set role authenticated');
    let result=await call(null,'CozyMuffin',2,3,dev);
    assert.equal(result.me,null); assert.equal(result.total_players,0);
    assert.ok(result.fillers.every(r=>r.character_id>=1&&r.character_id<=2&&r.frame_id>=1&&r.frame_id<=5));
    await db.exec('reset role');
    assert.equal((await db.query(`select count(*)::int as n from ${schema}.profiles`)).rows[0].n,1);
    assert.equal((await db.query(`select count(*)::int as n from ${schema}.players`)).rows[0].n,0);
    await db.exec('set role authenticated');
    result=await call(90,'CozyMuffin',2,3,dev);
    assert.equal(result.me.nickname,'CozyMuffin'); assert.equal(result.me.character_id,2); assert.equal(result.me.frame_id,3);
    assert.equal(result.top[0].nickname,'CozyMuffin');
    await db.exec('reset role');
    const reached=(await db.query(`select reached_at::text as t from ${schema}.players where user_id=$1`,[user])).rows[0].t;
    await db.exec('set role authenticated');
    result=await call(20,'УютнаяПанда',1,5,dev);
    assert.equal(result.me.stars,90); assert.equal(result.me.nickname,'УютнаяПанда'); assert.equal(result.me.frame_id,5);
    const legacy=(await db.query(`select public.leaderboard_sync${dev?'_dev':''}(null,true,'en',false) as r`)).rows[0].r;
    assert.equal(legacy.me.nickname,'УютнаяПанда'); // Older clients cannot erase profile fields.
    for(const values of [['A',1,1],['X'.repeat(19),1,1],[' Bad ',1,1],['Bad\nName',1,1],['Good',0,1],['Good',3,1],['Good',1,0],['Good',1,6],[null,1,1],['Good',null,1]])
      await assert.rejects(()=>call(null,...values,dev));
    await assert.rejects(()=>db.query(`select * from ${schema}.profiles`));
    await db.exec('reset role');
    assert.equal((await db.query(`select reached_at::text as t from ${schema}.players where user_id=$1`,[user])).rows[0].t,reached);
    await owner(other); await db.exec('set role authenticated');
    result=await call(null,'SunnyWaffle',2,2,dev);
    assert.equal(result.me,null); assert.equal(result.top[0].nickname,'УютнаяПанда');
    await db.exec('reset role');
    assert.equal((await db.query(`select count(*)::int as n from ${schema}.profiles`)).rows[0].n,2);
    await db.exec('set role anon');
    await assert.rejects(()=>call(null,'Injected',1,1,dev));
    await db.exec('reset role');
    await owner(''); await db.exec('set role authenticated');
    await assert.rejects(()=>call(null,'Injected',1,1,dev));
    await db.exec('reset role');
  }
  // Production and dev identities can be edited independently.
  await owner(user); await db.exec('set role authenticated');
  await call(null,'ProductionName',1,1,false);
  const devResult=await call(null,null,null,null,true);
  assert.equal(devResult.me.nickname,'УютнаяПанда');
  await db.exec('reset role');
  await db.exec(fs.readFileSync(root+'/supabase/migrations/011_player_profiles.sql','utf8'));
  await owner(user); await db.exec('set role authenticated');
  assert.equal((await call(null,null,null,null,false)).me.nickname,'ProductionName');
  await db.exec('reset role');
  await db.query('delete from auth.users where id=$1',[user]);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.profiles where user_id=$1',[user])).rows[0].n,0);
  console.log('PLAYER_PROFILES SQL passed: zero stars, profile updates, ranking unchanged, public rows, fillers, validation, ownership, legacy API, permissions, dev/prod, repeatable migration, cascade');
  await db.close();
})().catch(error=>{console.error(error);process.exit(1)});
