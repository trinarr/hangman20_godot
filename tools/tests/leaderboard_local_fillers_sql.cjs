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
  for (const name of fs.readdirSync(root+'/supabase/migrations').filter(n=>/^00[5-9]|^010/.test(n)).sort())
    await db.exec(fs.readFileSync(root+'/supabase/migrations/'+name,'utf8'));
  const user='00000000-0000-0000-0000-000000000001';
  await db.query('insert into auth.users values ($1)',[user]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user]);
  const call=async(stars=null, seed=false, language='ru', dev=false, top=true)=>(await db.query(
    `select public.leaderboard_sync${dev?'_dev':''}($1,$2,$3,$4) as r`,[stars,top,language,seed])).rows[0].r;
  await db.exec('set role authenticated');
  let result=await call(null,true);
  assert.equal(result.protocol_version,2); assert.equal(result.owner_id,user);
  assert.deepEqual(result.top,[]); assert.equal(result.me,null);
  assert.equal(result.total_players,0); assert.equal(result.fillers.length,100);
  const ru=result.fillers;
  const verifySeed=(rows,cis)=>{
    assert.equal(rows.length,100); assert.equal(new Set(rows.map(r=>r.player_id)).size,100);
    assert.equal(rows.filter(r=>r.player_id.startsWith('filler:cis:')).length,cis);
    rows.forEach((r,i)=>{assert.equal(r.rank,i+1);assert.equal(r.is_filler,true);assert.equal(r.is_me,false);
      assert.ok(Number.isInteger(r.stars)&&r.stars>=30&&r.stars<=100);
      if(i)assert.ok(rows[i-1].stars>=r.stars);});
  };
  verifySeed(ru,60);
  const en=(await call(null,true,'en')).fillers; verifySeed(en,20);
  assert.notDeepEqual(ru,en);
  result=await call(0,true);assert.equal(result.total_players,0);assert.deepEqual(result.fillers,ru);
  result=await call(1,true); assert.equal(result.top.length,1); assert.equal(result.top[0].stars,1);
  assert.deepEqual(result.fillers,ru); // fixed seed is unrelated to real scores
  result=await call(90,false); assert.equal(result.me.stars,90); assert.equal('fillers' in result,false);
  assert.ok(result.top.every(r=>!r.is_filler));
  result=await call(20,false);assert.equal(result.me.stars,90); // best score retained
  result=await call(null,true,'ru',false,false);assert.equal('fillers' in result,false);assert.equal('top' in result,false);
  const uuid=n=>'00000000-0000-0000-0000-'+String(n).padStart(12,'0');
  await db.exec('reset role');
  for(let n=2;n<=100;n++){
    await db.query('insert into auth.users values ($1)',[uuid(n)]);
    await db.query('insert into leaderboard_private.players(user_id,stars) values ($1,$2)',[uuid(n),n]);
    if(n===99){
      await db.exec('set role authenticated');result=await call(null,true);
      assert.equal(result.top.length,99);assert.equal(result.fillers.length,100);
      await db.exec('reset role');
    }
  }
  await db.exec('set role authenticated');result=await call(null,true);
  assert.equal(result.total_players,100);assert.equal(result.top.length,100);assert.deepEqual(result.fillers,[]);
  result=await call(null,true,'ru',true);assert.equal(result.total_players,0);verifySeed(result.fillers,60);
  await db.exec('reset role');
  const other=uuid(2);await db.query("select set_config('request.jwt.claim.sub',$1,false)",[other]);
  await db.exec('set role authenticated');
  const otherSeed=(await call(null,true,'ru',true)).fillers;assert.notDeepEqual(otherSeed,ru);
  await assert.rejects(()=>call(-1,true));
  await db.exec('reset role');
  await db.exec(`insert into auth.users(id)
    select ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid from generate_series(101,10000) n;
    insert into leaderboard_private.players(user_id,stars)
    select ('10000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,n from generate_series(101,10000) n;`);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user]);
  await db.exec('set role authenticated');
  result=await call(8500,false);assert.equal(result.total_players,10000);
  assert.equal(result.top.length,100);assert.equal(result.me.rank,null);assert.equal(result.me.top_percent,16);
  result=await call(9902,true);assert.equal(result.me.rank,100);assert.equal(result.me.top_percent,null);
  assert.deepEqual(result.fillers,[]);
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[other]);
  await db.exec(fs.readFileSync(root+'/supabase/migrations/010_leaderboard_local_fillers.sql','utf8'));
  assert.equal((await db.query("select count(*)::int as n from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('leaderboard_sync','leaderboard_sync_dev')")).rows[0].n,2);
  await db.exec('set role authenticated');assert.deepEqual((await call(null,true,'ru',true)).fillers,otherSeed);
  await db.exec('reset role');await db.exec('set role anon');await assert.rejects(()=>call(null,true));
  await db.exec('reset role');await db.query("select set_config('request.jwt.claim.sub','',false)");
  await db.exec('set role authenticated');await assert.rejects(()=>call(null,true));
  console.log('LEADERBOARD LOCAL FILLERS SQL passed: initial 100, empty/99/100 real, real-only updates, stable 30..100, locale/account mix, best scores, dev isolation, permissions and repeatable migration');
  await db.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
