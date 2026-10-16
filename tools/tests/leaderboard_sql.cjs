const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const root = require('node:path').resolve(__dirname, '../..');
(async () => {
  const db = new PGlite();
  await db.exec(`create role anon; create role authenticated; create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
  const migration = fs.readFileSync(root+'/supabase/migrations/005_leaderboard.sql','utf8') + '\n' + fs.readFileSync(root+'/supabase/migrations/006_leaderboard_percentile.sql','utf8') + '\n' + fs.readFileSync(root+'/supabase/migrations/007_leaderboard_fillers.sql','utf8') + '\n' + fs.readFileSync(root+'/supabase/migrations/008_leaderboard_filler_mix.sql','utf8') + '\n' + fs.readFileSync(root+'/supabase/migrations/009_leaderboard_positive_stars.sql','utf8');
  await db.exec(migration);
  const user = '00000000-0000-0000-0000-000000000001';
  await db.query('insert into auth.users values ($1)', [user]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user]);
  const call = async (stars=null, top=true, dev=false, language='en') => (await db.query(
    `select public.${dev ? 'leaderboard_sync_dev' : 'leaderboard_sync'}($1,$2,$3) as result`, [stars,top,language])).rows[0].result;
  await db.exec('set role authenticated');
  const approved = JSON.parse(fs.readFileSync(root+'/supabase/seeds/leaderboard_filler_nicknames_v2.json','utf8'));
  const assertMix = (board, total, language) => {
    const fillers = board.top.filter(p=>p.is_filler);
    const missing = total > 0 ? Math.max(0,100-total) : 0;
    const cisCount = Math.round(missing*(language==='ru' ? 0.6 : 0.2));
    assert.equal(fillers.length,missing);
    assert.equal(fillers.filter(p=>p.player_id.startsWith('filler:cis:')).length,cisCount);
    assert.equal(fillers.filter(p=>p.player_id.startsWith('filler:us_europe:')).length,missing-cisCount);
    assert.equal(new Set(fillers.map(p=>p.player_id)).size,missing);
    assert.equal(new Set(fillers.map(p=>p.nickname)).size,missing);
    const realRows=board.top.filter(p=>!p.is_filler);
    const minimum=realRows.length ? Math.min(...realRows.map(p=>p.stars)) : null;
    assert.equal(board.top.every(p=>p.stars>0),true);
    for (const [index,entry] of fillers.entries()) {
      const [,pool,slot] = entry.player_id.split(':');
      assert.equal(entry.nickname,approved[pool][Number(slot)-1]);
      const denominator=BigInt(2*Math.max(1,missing-1));
      const numerator=BigInt(minimum)*(denominator-BigInt(index));
      const expected=missing===1 ? minimum : Number((numerator+denominator-1n)/denominator);
      assert.equal(entry.stars,expected);
      assert.ok(entry.stars <= minimum);
      if(index>0) assert.ok(entry.stars<=fillers[index-1].stars);
      assert.equal(entry.is_me,false);
    }
  };
  let empty = await call();
  assert.equal(empty.total_players,0);
  assert.equal(empty.me,null);
  assert.equal(empty.top.length,0);
  assert.equal(empty.top.some(p=>p.stars===0),false);
  assertMix(empty,0,"en");
  assert.deepEqual(await call(),empty); // Stable selection and order.
  let russian = await call(null,true,false,'ru');
  assertMix(russian,0,"ru");
  assert.equal(russian.language,'ru');
  assert.deepEqual((await call(null,true,false,'ru-RU')).top,russian.top);
  assert.deepEqual((await call(null,true,false,'fr')).top,empty.top);
  assert.deepEqual((await call(null,true,false,null)).top,empty.top);
  assert.equal((await db.query('select public.leaderboard_sync() as result')).rows[0].result.top.length,0);
  const zeroSubmission=await call(0);
  assert.equal(zeroSubmission.me,null);
  assert.equal(zeroSubmission.total_players,0);
  assert.deepEqual(zeroSubmission.top,[]);
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.players')).rows[0].n,0);
  await db.exec('set role authenticated');
  assert.equal((await db.query('select public.leaderboard_sync($1,$2) as result',[null,true])).rows[0].result.language,'en');
  let snapshot = await call(50);
  assert.equal(snapshot.top.length, 100);
  assert.equal(snapshot.total_players,1);
  assert.equal(snapshot.top.filter(p=>p.is_filler).length,99);
  assert.equal(snapshot.top[0].is_filler,false);
  assert.equal(snapshot.top[0].nickname,'Player '+snapshot.me.player_id);
  assertMix(snapshot,1,"en");
  assert.equal(snapshot.me.rank, 1);
  assert.equal(snapshot.top[0].is_me, true);
  assert.equal(snapshot.me.stars, 50);
  assert.equal(typeof snapshot.me.player_id, 'string');
  assert.equal(snapshot.top[0].user_id, undefined);
  const ownId = snapshot.me.player_id;
  await db.exec('reset role');
  assert.equal((await db.query('select count(*)::int as n from auth.users')).rows[0].n,1);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.players')).rows[0].n,1);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.fillers')).rows[0].n,200);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_dev_private.fillers')).rows[0].n,200);
  for (const schema of ['leaderboard_private','leaderboard_dev_private']) {
    const composition = (await db.query(`select pool, style, count(*)::int as n from ${schema}.fillers group by pool,style order by pool,style`)).rows;
    assert.deepEqual(composition,[{pool:'cis',style:'casual',n:80},{pool:'cis',style:'slang',n:20},{pool:'us_europe',style:'casual',n:80},{pool:'us_europe',style:'slang',n:20}]);
  }
  // A second account gets a different stable sample, without registering a leaderboard row.
  const otherUser='00000000-0000-0000-0000-000000000002';
  await db.query('insert into auth.users values ($1)',[otherUser]);
  // Old zero-star records stay in storage but do not participate in any response.
  await db.query('insert into leaderboard_private.players(user_id,stars) values ($1,0)',[otherUser]);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[otherUser]);
  await db.exec('set role authenticated');
  const otherSnapshot=await call();
  assertMix(otherSnapshot,1,'en');
  assert.equal(otherSnapshot.me,null);
  assert.equal(otherSnapshot.total_players,1);
  assert.notDeepEqual(otherSnapshot.top.filter(p=>p.is_filler).map(p=>p.player_id),snapshot.top.filter(p=>p.is_filler).map(p=>p.player_id));
  assert.deepEqual(await call(),otherSnapshot);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user]);
  assert.deepEqual(await call(),snapshot);
  await db.exec('reset role');
  await db.exec('reset role');
  const originalTime = (await db.query('select reached_at::text as t from leaderboard_private.players where user_id=$1',[user])).rows[0].t;
  await db.exec('set role authenticated');
  assert.equal((await call(40,false)).me.stars,50);
  assert.equal((await call(50,false)).top,undefined);
  const emptyDev = await call(null,true,true);
  assert.equal(emptyDev.total_players,0);
  assert.equal(emptyDev.me,null);
  assert.deepEqual(emptyDev.top,empty.top);
  assert.equal((await call(7,true,true)).me.stars,7);
  assert.equal((await call()).me.stars,50);
  await assert.rejects(()=>call(-1));
  await assert.rejects(()=>call(2000000001));
  await assert.rejects(()=>call(100,null));
  await assert.rejects(()=>db.query('select * from leaderboard_private.players'));
  await assert.rejects(()=>db.query('select * from leaderboard_dev_private.players'));
  await assert.rejects(()=>db.query('select * from leaderboard_private.fillers'));
  await assert.rejects(()=>db.query('select * from leaderboard_dev_private.fillers'));
  await assert.rejects(()=>db.query("update leaderboard_private.fillers set nickname='Injected'"));
  await assert.rejects(()=>db.query('update leaderboard_private.players set stars=900'));
  await db.exec('reset role');
  assert.equal((await db.query('select reached_at::text as t from leaderboard_private.players where user_id=$1',[user])).rows[0].t,originalTime);
  // Populate 200 opponents. Only the compact top, never the full population, is returned.
  await db.exec(`insert into auth.users select md5('opponent'||n)::uuid from generate_series(1,200) n;
    insert into leaderboard_private.players(user_id,stars,reached_at)
      select md5('opponent'||n)::uuid,1000+n,'2026-01-01'::timestamptz from generate_series(1,200) n;`);
  await db.exec('set role authenticated');
  snapshot = await call();
  assert.equal(snapshot.top.filter(p=>p.is_filler).length,0);
  assert.equal(snapshot.top.length,100);
  assert.equal(snapshot.top[0].stars,1200);
  assert.equal(snapshot.top[99].stars,1101);
  assert.equal(snapshot.top[99].rank,100);
  assert.equal(snapshot.me.rank,null);
  assert.equal(snapshot.me.top_percent,100);
  assert.equal(snapshot.total_players,201);
  assert.equal(snapshot.top.some(p=>p.is_me),false);
  assert.equal((await call(1300)).me.rank,1);
  assert.equal((await call()).top[0].player_id,ownId);
  await db.exec('reset role');
  // Fix timestamps to verify exact tie ordering and unique places.
  await db.exec(`update leaderboard_private.players set stars=100,reached_at='2026-01-01' where stars>0;`);
  await db.exec('set role authenticated');
  snapshot = await call();
  assert.equal(snapshot.me.rank,1);
  assert.equal(new Set(snapshot.top.map(p=>p.rank)).size,100);
  await db.exec('reset role');
  await db.query("update leaderboard_private.players set reached_at='2026-01-02' where user_id=$1",[user]);
  await db.exec('set role authenticated');
  assert.equal((await call()).me.rank,null);
  assert.equal((await call()).me.top_percent,100);
  await db.exec('reset role');
  await db.exec(migration);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_private.players where stars>0')).rows[0].n,201);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_dev_private.players')).rows[0].n,1);
  assert.equal((await db.query('select stars from leaderboard_dev_private.players')).rows[0].stars,7);
  // Independent dev population: 0/1/99/100/101 real participants.
  for (const size of [0,1,7,42,50,90,95,97,98,99,100,101]) {
    await db.exec('reset role');
    await db.exec('delete from leaderboard_dev_private.players');
    await db.query(`insert into leaderboard_dev_private.players(user_id,stars)
      select id,100 from auth.users order by id limit $1`,[size]);
    await db.exec('set role authenticated');
    const board = await call(null,true,true,'ru');
    assert.equal(board.total_players,size);
    assert.equal(board.top.length,size===0 ? 0 : 100);
    assert.equal(board.top.filter(p=>!p.is_filler).length,Math.min(size,100));
    assert.equal(board.top.filter(p=>p.is_filler).length,size===0 ? 0 : Math.max(100-size,0));
    assert.deepEqual(board.top.map(p=>p.rank),Array.from({length:size===0 ? 0 : 100},(_,i)=>i+1));
    assert.equal(new Set(board.top.map(p=>p.player_id)).size,size===0 ? 0 : 100);
    assert.equal(board.top.slice(0,Math.min(size,100)).every(p=>!p.is_filler),true);
    assertMix(board,size,'ru');
    const englishBoard=await call(null,true,true,'en');
    assertMix(englishBoard,size,'en');
    assert.deepEqual((await call(null,true,true,'ru')).top,board.top);
    assert.deepEqual((await call(null,true,true,'en')).top,englishBoard.top);
  }
  await db.exec('reset role');
  await db.exec('delete from leaderboard_dev_private.players');
  await db.query('insert into leaderboard_dev_private.players(user_id,stars) values ($1,7)',[user]);
  // Exact score endpoints, integer rounding, singleton and maximum supported score.
  for (const [size,minimum] of [[95,100],[95,101],[99,77],[1,1],[1,2],[98,3],[1,2000000000]]) {
    await db.exec('reset role');
    await db.exec('delete from leaderboard_dev_private.players');
    await db.query('insert into leaderboard_dev_private.players(user_id,stars) select id,$1 from auth.users order by id limit $2',[minimum,size]);
    await db.exec('set role authenticated');
    const board=await call(null,true,true);
    assertMix(board,size,'en');
    const stars=board.top.filter(p=>p.is_filler).map(p=>p.stars);
    if(size===95 && minimum===100) assert.deepEqual(stars,[100,88,75,63,50]);
    if(size===95 && minimum===101) assert.deepEqual(stars,[101,89,76,64,51]);
    assert.equal(stars[0],minimum);
    assert.equal(stars.at(-1),stars.length===1 ? minimum : Math.ceil(minimum/2));
    assert.equal(board.top.slice(0,size).every(p=>!p.is_filler),true);
  }
  await db.exec('reset role');
  await db.exec('delete from leaderboard_dev_private.players');
  await db.query('insert into leaderboard_dev_private.players(user_id,stars) values ($1,0)',[user]);
  await db.exec('set role authenticated');
  assert.deepEqual((await call(null,true,true)).top,[]);
  assert.equal((await call(null,false,true)).me,null);
  assert.equal((await call(null,false,true)).total_players,0);
  assert.equal((await call(7,true,true)).me.stars,7);
  await db.exec('reset role');
  // A 10,000-player board: percentile is rounded upward, with no exposed exact rank.
  await db.exec(`insert into auth.users select md5('percentile'||n)::uuid from generate_series(1,9799) n;
    insert into leaderboard_private.players(user_id,stars)
      select md5('percentile'||n)::uuid,1 from generate_series(1,9799) n;`);
  const setPosition = async rank => {
    await db.exec('reset role');
    await db.query('update leaderboard_private.players set stars=case when user_id=$1 then 0 else 1 end',[otherUser]);
    await db.query(`update leaderboard_private.players set stars=200 where player_id in
      (select player_id from leaderboard_private.players where user_id <> $1 and stars>0 order by player_id limit $2)`,[user,rank-1]);
    await db.query('update leaderboard_private.players set stars=100 where user_id=$1',[user]);
    await db.exec('set role authenticated');
    return call();
  };
  for (const [rank,percent] of [[600,6],[1247,13],[101,2],[9999,100],[10000,100]]) {
    snapshot = await setPosition(rank);
    assert.equal(snapshot.total_players,10000);
    assert.equal(snapshot.top.length,100);
    assert.equal(snapshot.me.rank,null);
    assert.equal(snapshot.me.top_percent,percent);
  }
  snapshot = await setPosition(100);
  assert.equal(snapshot.me.rank,100);
  assert.equal(snapshot.me.top_percent,null);
  await db.exec('reset role');
  await db.exec(migration);
  await db.exec('set role authenticated');
  assert.equal((await call()).me.rank,100);
  // Dev uses its own population, not the 10,000 production participants.
  snapshot = await call(null,true,true);
  assert.equal(snapshot.total_players,1);
  assert.equal(snapshot.me.rank,1);
  assert.equal(snapshot.me.top_percent,null);
  await db.exec('reset role');
  await db.exec('set role anon');
  await assert.rejects(()=>call()); await assert.rejects(()=>call(0,true,true));
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub','',false)");
  await db.exec('set role authenticated');
  await assert.rejects(()=>call()); await assert.rejects(()=>call(null,true,true));
  await db.exec('reset role');
  await db.query('delete from auth.users where id=$1',[user]);
  assert.equal((await db.query('select count(*)::int as n from leaderboard_dev_private.players')).rows[0].n,0);
  assert.equal((await db.query("select count(*)::int as n from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('leaderboard_sync','leaderboard_sync_dev')")).rows[0].n,2);
  console.log('LEADERBOARD SQL passed: zero exclusion, no zero-score registration, empty-positive board, N..ceil(N/2) interpolation, singleton, odd and maximum N, server fillers, 80 casual + 20 slang per pool, stable per-account random selection, exact 60/40 and 80/20 mixes, partial-count rounding, 0/1/99/100/101 boundary, no fake accounts or ranks, no overload ambiguity, top-100, percentile outside top, 10,000 participants, rounding boundaries, own rank inside top, best stars, ties, dev isolation, permissions, repeatable migrations, cascade');
  await db.close();
})().catch(error => {console.error(error); process.exitCode=1;});
