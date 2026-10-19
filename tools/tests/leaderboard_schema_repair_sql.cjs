const { PGlite } = require('@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const migration = name => fs.readFileSync(path.join(root,'supabase/migrations',name),'utf8');
const repair = migration('015_leaderboard_filler_schema_repair.sql');
const canonical = JSON.parse(fs.readFileSync(path.join(root,'supabase/seeds/leaderboard_filler_nicknames_v4.json'),'utf8'));
(async () => {
  for (const missingAppearance of [true,false]) {
    const db = new PGlite();
    await db.exec(`create role anon; create role authenticated; create schema auth;
      create table auth.users(id uuid primary key);
      create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
      grant usage on schema auth to authenticated; grant execute on function auth.uid() to authenticated;`);
    for (const name of fs.readdirSync(path.join(root,'supabase/migrations')).filter(n=>/^(00[5-9]|01[0-4])_/.test(n)).sort()) {
      if (missingAppearance && name.startsWith('013_')) continue;
      await db.exec(migration(name));
    }
    const user='00000000-0000-0000-0000-000000000001';
    await db.query('insert into auth.users values ($1)',[user]);
    await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user]);
    const before = {};
    for (const dev of [false,true]) {
      const schema = dev?'leaderboard_dev_private':'leaderboard_private';
      const rpc = `public.leaderboard_sync${dev?'_dev':''}`;
      await db.query(`insert into ${schema}.players(user_id,stars) values ($1,235)`,[user]);
      await db.query(`insert into ${schema}.profiles(user_id,nickname,character_id,frame_id) values ($1,'MyName',2,5)`,[user]);
      if (!missingAppearance)
        await db.exec(`update ${schema}.fillers set character_id=3-character_id,frame_id=frame_id%5+1 where slot=1;`);
      const appearanceFields = missingAppearance?'':',character_id,frame_id';
      before[dev] = {
        fillers:(await db.query(`select pool,slot,nickname,style${appearanceFields} from ${schema}.fillers order by pool,slot`)).rows,
        players:(await db.query(`select * from ${schema}.players`)).rows,
        profiles:(await db.query(`select * from ${schema}.profiles`)).rows,
        fn:(await db.query(`select pg_get_functiondef('${rpc}(bigint,boolean,text,boolean,text,integer,integer)'::regprocedure) as definition`)).rows[0].definition,
      };
      if (missingAppearance) {
        for (const seed of [false,true])
          await assert.rejects(()=>db.query(`select ${rpc}(235,true,'en',$1,'MyName',2,5)`,[seed]),error=>error.code==='42703');
      }
    }
    for (let repeat=0;repeat<2;repeat++) {
      await db.exec(repair);
      for (const dev of [false,true]) {
        const schema = dev?'leaderboard_dev_private':'leaderboard_private';
        const rpc = `public.leaderboard_sync${dev?'_dev':''}`;
        const rows=(await db.query(`select pool,slot,nickname,style,character_id,frame_id from ${schema}.fillers order by pool,slot`)).rows;
        if (missingAppearance) {
          assert.deepEqual(rows.map(({character_id,frame_id,...rest})=>rest),before[dev].fillers);
          for (const row of rows) {
            assert.equal(row.character_id,canonical[row.pool][row.slot-1].character_id);
            assert.equal(row.frame_id,canonical[row.pool][row.slot-1].frame_id);
          }
        } else assert.deepEqual(rows,before[dev].fillers);
        assert.deepEqual((await db.query(`select * from ${schema}.players`)).rows,before[dev].players);
        assert.deepEqual((await db.query(`select * from ${schema}.profiles`)).rows,before[dev].profiles);
        assert.equal((await db.query(`select pg_get_functiondef('${rpc}(bigint,boolean,text,boolean,text,integer,integer)'::regprocedure) as definition`)).rows[0].definition,before[dev].fn);
        await db.exec('set role authenticated');
        for (const seed of [false,true]) {
          const result=(await db.query(`select ${rpc}(235,true,'en',$1,'MyName',2,5) as r`,[seed])).rows[0].r;
          assert.equal(result.me.stars,235); assert.equal(result.me.nickname,'MyName');
          assert.equal(result.me.rank,1); assert.equal(result.me.character_id,2); assert.equal(result.me.frame_id,5);
          if (seed) assert.ok(result.fillers.length===100 && result.fillers.every(r=>r.character_id>=1&&r.character_id<=2&&r.frame_id>=1&&r.frame_id<=5));
        }
        await assert.rejects(()=>db.query(`select * from ${schema}.fillers`));
        await db.exec('reset role');
        await db.exec('set role anon');
        await assert.rejects(()=>db.query(`select ${rpc}()`));
        await db.exec('reset role');
        for (const [column,value] of [['character_id',0],['character_id',3],['frame_id',0],['frame_id',6],['character_id',null],['frame_id',null]])
          await assert.rejects(()=>db.query(`update ${schema}.fillers set ${column}=$1 where slot=1`,[value]));
      }
    }
    await db.close();
  }
  console.log('SCHEMA_REPAIR SQL passed: reproduced 42703 with seed=false/true, repaired dev/prod, canonical IDs, preserved healthy/custom data and 014 RPCs, constraints, privileges, repeat application');
})().catch(error=>{console.error(error);process.exit(1);});
