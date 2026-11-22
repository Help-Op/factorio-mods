# Commands

Central list of in-game commands for testing. One command per code block, ready to paste.
Game version: 2.1.21. `/c` commands disable achievements for that save.

## Hostile Territory: debug commands

| Command | What it does |
|---------|--------------|
| `/ht-territory` | Id and state of the territory you stand in |
| `/ht-set-state <state>` | Force the state of the territory you stand in (`hostile`, `challenge`, `claimed`, `warning`, `crusade`) |
| `/ht-challenges` | List running challenges |
| `/ht-attacks` | Cancelled vanilla attacks and the crusade budget |
| `/ht-crusade` | Crusade budget, next target and cost, active crusade status |
| `/ht-crusade-cancel` | End the active crusade: army removed, target back to `claimed` |

## Crusades

Force a crusade: stand in a territory near enemy nests (a crusade needs a nest to stage from), then:

```
/ht-set-state claimed
```

Give it a big budget and clear the cooldown (the next check runs within a minute):

```
/c __Hostile-territory__ storage.crusade_budget = 1e6; storage.crusade_cooldown_until = 0
```

Speed up the rally build (safe when no crusade is running):

```
/c __Hostile-territory__ local c = storage.crusade if c then c.next_builder_tick = game.tick c.build_time = 600 end
```

Rally health check: set the nearest medium rally to 1 HP and print its health 1 s later (it must not heal):

```
/c local e=game.player.surface.find_entities_filtered{name="ht-rally-medium",limit=1}[1] e.health=1 game.print(e.health) script.on_nth_tick(60,function() game.print(e.valid and e.health) script.on_nth_tick(60,nil) end)
```

## Wyrms and water (patrol.lua)

Reroute status per territory (`rerouted` / `dry` = no change needed / `water` = engine path kept / pending):

```
/c __Hostile-territory__ local c={} for _,r in pairs(storage.territories) do local k=r.patrol and r.patrol.result or "pending" c[k]=(c[k] or 0)+1 end game.print(serpent.line(c))
```

Reroute stats for the territory you stand in (points, snapped, dropped, detours, chunks, ticks, result):

```
/c __Hostile-territory__ local s=game.player.surface local t=s.get_territory_for_chunk({math.floor(game.player.position.x/32),math.floor(game.player.position.y/32)}) for _,r in pairs(storage.territories) do if r.territory==t then game.print(serpent.line(r.patrol)) end end
```

Draw the patrol path of the territory you stand in (magenta, for 60 s, only you see it):

```
/c local p=game.player local t=p.surface.get_territory_for_chunk({math.floor(p.position.x/32),math.floor(p.position.y/32)}) if not t then p.print("No territory here.") return end local path=t.get_patrol_path() for i,a in pairs(path) do rendering.draw_line{color={1,0,1},width=4,from=a,to=path[i%#path+1],surface=p.surface,players={p},time_to_live=3600} end p.print(#path.." points")
```

Reroute the territory you stand in again, now (debug; prints its stats):

```
/c __Hostile-territory__ local p=game.player local t=p.surface.get_territory_for_chunk({math.floor(p.position.x/32),math.floor(p.position.y/32)}) local id=t and script.register_on_object_destroyed(t) p.print(serpent.line(id and remote.call("hostile-territory-debug","reroute",id)))
```

Elevation noise vs. real water in the chunk you stand in (Q-EB3b-8; sample at integer positions):

```
/c local s=game.player.surface local cx,cy=math.floor(game.player.position.x/32),math.floor(game.player.position.y/32) local pos={} for x=0,31 do for y=0,31 do pos[#pos+1]={cx*32+x,cy*32+y} end end local e=s.calculate_tile_properties({"elevation"},pos).elevation local m=0 for k,p in pairs(pos) do if (e[k]<0)~=s.get_tile(p[1],p[2]).collides_with("water_tile") then m=m+1 end end game.print(m.." of 1024 tiles differ")
```

## Wyrm control (EB3c)

Since territory-brain B2 the territory guardians are brains, not wyrms; these commands act on the nearest segmented unit, so they work on brains too (a brain has all speeds 0: "send", "enrage" and "hold" don't move it; the `set_body_nodes` jump does).

All act on the wyrm nearest to you. Results of the headless tests: `enemy-balancing-plan.md` EB3c.

Send it to where you stand now (`investigating`; it patrols again once it arrives):

```
/c local p=game.player local u,b for _,x in pairs(p.surface.get_segmented_units()) do local h=x.segments[1].position local d=(h.x-p.position.x)^2+(h.y-p.position.y)^2 if not b or d<b then u,b=x,d end end u.set_ai_state{type=defines.segmented_unit_ai_state.investigating,destination=p.position} p.print("sent, "..math.floor(math.sqrt(b)).." tiles away")
```

Enrage it towards where you stand (`enraged_at_nothing`, fast, for 30 s):

```
/c local p=game.player local u,b for _,x in pairs(p.surface.get_segmented_units()) do local h=x.segments[1].position local d=(h.x-p.position.x)^2+(h.y-p.position.y)^2 if not b or d<b then u,b=x,d end end u.set_ai_state{type=defines.segmented_unit_ai_state.enraged_at_nothing,destination=p.position,last_damage_time=game.tick} p.print("enraged, "..math.floor(math.sqrt(b)).." tiles away")
```

Hold it still (`speed = 0` every tick; a second call holds a second wyrm instead):

```
/c local p=game.player local u,b for _,x in pairs(p.surface.get_segmented_units()) do local h=x.segments[1].position local d=(h.x-p.position.x)^2+(h.y-p.position.y)^2 if not b or d<b then u,b=x,d end end script.on_nth_tick(1,function() if u.valid then u.speed=0 end end) p.print("holding")
```

Release it:

```
/c script.on_nth_tick(1,nil) game.print("released")
```

Move its whole body 30 tiles east (`set_body_nodes`, a jump):

```
/c local p=game.player local u,b for _,x in pairs(p.surface.get_segmented_units()) do local h=x.segments[1].position local d=(h.x-p.position.x)^2+(h.y-p.position.y)^2 if not b or d<b then u,b=x,d end end local n=u.get_body_nodes() for _,q in pairs(n) do q.x=q.x+30 end u.set_body_nodes(n) p.print("moved")
```

## Cheating mod: test kits

| Command | What it does |
|---------|--------------|
| `/cheat-kit` | Demolisher kit: mech armor, railgun, rockets, tesla, spidertron |
| `/cheat-kit <name>` | Tier kit, no armor: `pistol`, `smg-yellow`, `ring0` (SMG + 100 yellow magazines = 1 stack, challenge-feel CF-D3), `smg-red`, `smg-uranium`, `shotgun`, `flamethrower`, `rockets` |
| `/cheat-kit ring1` | Oil-ring kit (OR-D8/D9/D12): heavy armor, SMG + 200 red magazines (2 stacks), shotgun + 100 shells, 20 grenades; researches physical damage, shooting speed and stronger explosives 1–2 for your force (stays after `/cheat-clear`) |
| `/cheat-kit ring2` | Ring-2 kit (ring2-challenge R2-D33, blue era, no tank): modular armor (2 energy shields, 2 batteries, solar panels), SMG + 600 red magazines, flamethrower + 100 fuel, rocket launcher + 200 rockets, 100 explosive rockets, 10 gun turrets, 10 poison + 10 slowdown capsules; researches physical damage and shooting speed 1–4, stronger explosives and refined flammables 1–2 (stays after `/cheat-clear`) |
| `/cheat-clear` | Bare character: no armor, guns, ammo, items or health bonus |

Map setting **Give the demolisher kit on spawn** (Settings → Mod settings → Map), default off.

## Challenge feel: first-ring test (challenge-feel-plan.md E1)

Ring 0 = the 4 territories right outside the 150-tile safe zone (brains ~200–390 tiles from spawn); ring 1 = the next 12 (ring-layout R1). No crude oil in ring 0 or the safe zone; `/ht-brains` shows a GPS link to the guaranteed ring-1 oil patch. Shooting a nest or worm of a brain base starts the challenge in phase "siege" (4–7 every 10 s, the base doesn't regrow); the brain engaging starts "wake" (E9). Wake: groups of 11–17 small biters out of the nests every 8 s, a swarm of 250 once the brain (1125 HP, ~150 bullets) is below 60 % (phase "swarm", was "climax"); each swarm biter takes a wide detour (35 tiles out) to its own point on a ring around your sides and back before attacking (E4/E5). Every 3rd swarm biter guards the brain's front for 10 s instead (E7). After the swarm, a last-stand group of 5 every 2 s until the brain dies (E6/E9). The small brain has no fissures, and its ash cloud ("shockwave") slows its own biters ×0.45 too (E3/E4). Start a fresh map, then:

Kit (bare character, SMG, 1 stack of yellow ammo):

```
/cheat-kit ring0
```

GPS link to the nearest brain base (needs the `ht-map-check` mod, see "Territory brains and bases"):

```
/ht-map-nearest
```

Teleport 60 tiles east of the nearest brain (close enough for a challenge, not yet in it):

```
/c local p=game.player local b,bd for _,u in pairs(p.surface.get_segmented_units()) do local h=u.segments[1] if h then local d=(h.position.x-p.position.x)^2+(h.position.y-p.position.y)^2 if not bd or d<bd then b,bd=h.position,d end end end if b then p.teleport(p.surface.find_non_colliding_position("character",{b.x+60,b.y},20,1)) end
```

Challenge status (ring, phase, brain %, alive, next group or swarm left):

```
/ht-challenges
```

Yellow magazines left (ammo slot + inventory; the magazine in the gun counts as a whole one):

```
/c local c=game.player.character local n=c.get_inventory(defines.inventory.character_ammo).get_item_count("firearm-magazine")+c.get_main_inventory().get_item_count("firearm-magazine") game.player.print(n.." magazines left")
```

## Oil ring: ring-1 test (oil-ring-challenge-plan.md OR-E1, OR-E2, OR-E6, OR-E7, OR-E8)

Ring 1 = the 12 territories behind ring 0, where oil starts. Every ring-1 territory has the **oil ring brain** (`hf-brain-ring1`: 5000 HP, no regen, no fissures, blue-violet tint). Same phases as ring 0, from the nests: siege 8–14 every 10 s, wake 22–34 every 8 s (max 140 alive), then **three surges** (OR-D28, 750 in total): at 80 % the swarm from the nests (350), at 55 % they **encircle** you (250 walk to a full ring around you, then attack), at 30 % **frenzy** (150, the last stand doubles and the shockwave pulses twice as often). Between and after the surges a last-stand group of 10 every 2 s (max 240 alive) that never runs dry: out of the brain once the nests are dead (OR-D30). Wake / siege groups shrink with the share of nests still alive. Small biters only (OR-D6), 20 % slower than normal ones (every challenge unit in ring 0 and 1, OR-D22). The shotgun does ×2 damage (one pellet still kills a small biter), vanilla reload (40 ticks).

**Pressure director** (OR-E2, ring 1 only): from the **wake** on (OR-E10; the wake keeps its group size and comes out of the brain once the nests are dead), the damage you take is kept around **8.3 HP/s** (your max health / 30, measured over 3 s: ~30 s of non-stop attack before you die). Slots for biters within 6 tiles grow while you take little damage (you're killing them) and shrink when you take more than the budget. Base defenders (not from the challenge) aren't held. The brain's shockwave shows only its expanding edge, half as dense, and the idle brain gives off no ash cloud (OR-D26, OR-D31). In the ring-0 / ring-1 brain's ash cloud you and its biters are both slowed ×0.45 (you 0.1125, biters 0.081: the same 72 % as outside, OR-D27).

**A brain that thinks** (OR-E6, OR-E7, ring 1 only):

- **Squads:** biters that aren't on you join one of six squads around you: pin (between you and the brain), flank left / right, back, cut-off (where you're heading), reserve (by the brain). Squads follow you, gather, **stand still ~1.5 s (a red circle on the ground)**, then charge together, usually from 2–3 sides. 20 come at once when nothing is near you.
- **Shield links** (OR-E8 E8-A2, replaces OR-E7's bearers per surge): ring-1+ brain bases have **4 anchor nests 32 tiles out** (biter spawners, outside the inner ring at 18), each with a **blue dashed line** to the brain. From the start of the fight the brain is **shielded** (blue ring: it takes 10 % damage) while any link lives. Kill an anchor and a **shield bearer** (cyan big biter) comes out of it and walks in to 6–10 tiles from the brain on that side; the line moves to it. Kill all 4 anchors and their 4 bearers and the brain is **open for good** (red ring, "The links are broken: the brain is exposed!"). The frenzy (30 %) opens it too. Surges no longer bring bearers. Hitting an anchor starts the siege, killing one **doesn't** wake the brain; anchors don't send waves. They regrow like the rest of the base.
- **Stream** (OR-E10, off since OR-E11: the queens are the stream now): while you take little damage (units dealt you < 30 % of the budget, 2.5 HP/s, over the last 5 s), the squads didn't gather and tell but sent their nearest biters at you non-stop.
- **Queens** (OR-E8 E8-B): once **any nest** of the base dies (siege too), the nest nearest to you releases a **queen** (big purple biter, 500 HP, slow) with an **escort of 8** small biters; up to **4** at a time, a new one every 20 s while fewer live. She walks with her escort to a spot **50–70 tiles** from you and holds there; the 4 queens spread **all around you** (~90° apart, OR-E12). She spawns **3 small biters every 4 s**, **while walking too**, which run **straight at you** (on top of the surges; paused while 500+ challenge units live). **While you take little damage** (< 2.5 HP/s over 5 s) the hive turns the queens up: every 5 s calm adds 1 biter per spawn, up to **12 per 4 s** per queen; take more than the budget and they drop back to 3 (OR-E11). She only picks a new spot when hers ends up closer than 40 or further than 80 tiles from you. Come within **25 tiles** of her and she **retreats** away from you (to her side's spot, 50–70 tiles), while her escort stays and attacks you (it doesn't rejoin her); move 20 tiles away and she picks a new spot. **No nests left → no new queens.** ("A queen crawls out of a nest!")
- **Reactions:** shoot the brain and the reserve charges you (from surge 1). Stand still for 2 s and every squad charges (from surge 2).
- **Closing ring** (surge 2, 55 %): 250 biters form a ring 16 tiles around where you stood, then step in 2 tiles every 3 s and charge at 6. Get out of the ring and it breaks up into squads.
- **Rock arena** (surge 2): a ring of huge rocks rises 28 tiles around you (brown circles first) with 4+ gaps of 4 tiles or more. The rocks **stay**, also after the fight. (Rock walls on your path from surge 1 are switched off for now, OR-D54.)
- **Regroup** (OR-E7; never in the frenzy): run from the swarm (faster than 3 tiles/s, 20+ biters within 25 tiles but none catching you, for 5 s) and the **whole hive pulls back** into 12 packs on a ring around you that follows you; only the way to the brain stays open (OR-E13). The packs spread along the ring, it **tightens from 30 to 20 tiles** over the 10 s hold, and new biters (queens) join the **emptiest** pack, so your far side fills up (only the shield bearers stay put), leaving the brain open as a lure: at least 10 s of free shots. After that, come within 15 tiles of the brain (or wait until 25 s are up; the frenzy springs it too) and every pack charges you at once from its side.
- **Chokepoint** (OR-E9): hold a choke (a cliff / water gap) and keep killing what comes through, without moving or getting hurt, and the brain notices ("The hive won't walk into your guns."): it stops sending biters through the gap, they wait out of range (22 tiles) and try to come round your other sides ("The hive comes around!"). Move 10 tiles away and it ends.
- **Early wake** (OR-D55): destroying the first nest of the base in the siege wakes the brain (wake phase, shockwave on).

Squads follow you or stay where they were first placed, for comparing (default on; no parameter shows it):

```
/ht-antikite off
```

```
/ht-antikite on
```

**Telemetry:** every challenge writes `%APPDATA%\Factorio\script-output\ht-telemetry\<start tick>-t<territory>.csv` (a row per second: phase, brain %, HP, HP/s taken, budget, director state, biters touching / in the ring / waiting in squads, surge, nests, shield, units per squad state, closing ring, running totals of charges / charged units / guard rushes / stand-still punishes / rocks / openings, bearers alive, regroup state and count, arena rocks, the biggest hit this second and what dealt it (your own damage, e.g. grenades, as `own explosion`), choke (on / off, direction) and squads with no way round, anchors alive, `brain_take` (share of a hit the brain keeps now), `links` (anchors + bearers alive), `queens` (alive), `queen_spawned` (biters the queens spawned so far), `stream` (on / off) and `streamed` (units sent by the stream so far), `queen_level` (0–9: extra biters per queen spawn), kills by damage type, ammo left). Written every 30 s, when you die (with the 5 biggest hits of the last 3 s and what dealt them), and when the challenge ends; the last line is a summary (outcome, seconds per phase, peak HP/s, longest time over budget, deaths).

Start a fresh map, then:

Kit (heavy armor, SMG + red ammo, shotgun + shells, 20 grenades, research level 2):

```
/cheat-kit ring1
```

Teleport next to the nearest oil ring brain (45 tiles from it on the spawn side, inside its territory; generates only the chunks around that brain first). `/ht-goto-ring 0` for ring 0:

```
/ht-goto-ring
```

Cliffs and water within 50 tiles of the nearest oil ring brain (PT10: a cliff next to the brain made a chokepoint; pick a brain with 0 cliffs and little water for balance tests):

```
/c local s=game.player.surface local p=game.player.position local b for _,u in pairs(s.get_segmented_units()) do local h=u.segments[1] if h and u.prototype.name=="hf-brain-ring1" and (not b or (h.position.x-p.x)^2+(h.position.y-p.y)^2<(b.x-p.x)^2+(b.y-p.y)^2) then b=h.position end end game.print(b and ("Brain [gps="..math.floor(b.x)..","..math.floor(b.y).."]: cliffs within 50: "..s.count_entities_filtered{position=b,radius=50,type="cliff"}..", water tiles: "..s.count_tiles_filtered{position=b,radius=50,collision_mask="water_tile"}) or "No oil ring brain loaded.")
```

Anchors around the nearest oil ring brain (count + GPS; want 4):

```
/c local s=game.player.surface local p=game.player.position local b for _,u in pairs(s.get_segmented_units()) do local h=u.segments[1] if h and u.prototype.name=="hf-brain-ring1" and (not b or (h.position.x-p.x)^2+(h.position.y-p.y)^2<(b.x-p.x)^2+(b.y-p.y)^2) then b=h.position end end if not b then game.print("No oil ring brain loaded.") return end local n=0 for _,e in pairs(s.find_entities_filtered{position=b,radius=36,type="unit-spawner",force="enemy"}) do if (e.position.x-b.x)^2+(e.position.y-b.y)^2>=29^2 then n=n+1 game.print("Anchor [gps="..math.floor(e.position.x)..","..math.floor(e.position.y).."]") end end game.print("Brain [gps="..math.floor(b.x)..","..math.floor(b.y).."]: "..n.." anchors")
```

Build the anchor ring on a save from before OR-E8 (regrow rounds: each builds one missing piece per hostile base, anchors come after the inner base; run it again until the count above says 4):

```
/c game.print(remote.call("hostile-territory-debug","regrow",4).." pieces built")
```

Ammo left per type (ammo slots + inventory):

```
/c local c=game.player.character local t={} for _,n in pairs({"piercing-rounds-magazine","shotgun-shell","grenade"}) do t[#t+1]=n.." "..(c.get_inventory(defines.inventory.character_ammo).get_item_count(n)+c.get_main_inventory().get_item_count(n)) end game.player.print(table.concat(t,", "))
```

Telemetry summary of a fight (terminal, not in game; balance pass): per phase / surge length, HP/s, alive, touching, queen biters per second, queens, level; pull-backs; damage spikes (> 4 HP in a second). File names without a folder are read from `ht-telemetry`:

```bash
python tools/ht-telemetry-summary.py 1943-t8.csv
```

## Enemies: spawn and test

10 medium biters, 20 tiles east of you:

```
/c local p=game.player for i=1,10 do p.surface.create_entity{name="medium-biter",position={p.position.x+20,p.position.y+i}} end
```

3 behemoth biters, 30 tiles east of you:

```
/c local p=game.player for i=1,3 do p.surface.create_entity{name="behemoth-biter",position={p.position.x+30,p.position.y+i*3}} end
```

One biter of each tier in a row, 25 tiles east of you (small, medium, big, behemoth from north to south):

```
/c local p=game.player for i,n in pairs({"small-biter","medium-biter","big-biter","behemoth-biter"}) do p.surface.create_entity{name=n,position={p.position.x+25,p.position.y-15+i*6}} end
```

Biter speeds as the game sees them (EB3):

```
/c for _,n in pairs({"small-biter","medium-biter","big-biter","behemoth-biter"}) do game.print(n.." "..prototypes.entity[n].speed) end
```

Remove armor only (keeps the rest):

```
/c game.player.get_inventory(defines.inventory.character_armor).clear()
```

## Hostile Fauna

Check the nest rules table (`mod-data`):

```
/c game.print(serpent.line(prototypes.mod_data["hf-nest-rules"].data))
```

EB2 test units, spawned 15 tiles east of you. Swap the name: `hf-test-kiter` (green), `hf-test-strafer` (cyan), `hf-test-thorns` (yellow), `hf-test-splitter` (magenta):

```
/c local p=game.player p.surface.create_entity{name="hf-test-kiter",position={p.position.x+15,p.position.y}}
```

Three of each test unit in a row, 20 tiles east of you:

```
/c local p=game.player for i,n in pairs({"hf-test-kiter","hf-test-strafer","hf-test-thorns","hf-test-splitter"}) do for j=1,3 do p.surface.create_entity{name=n,position={p.position.x+20+j*2,p.position.y+i*6}} end end
```

Check the player running speed (0.25 = 15 tiles/s):

```
/c game.print(prototypes.entity["character"].running_speed)
```

## Counter-artillery test

Fire a slow artillery shell 300 tiles east of you (speed 0.2, so about 25 s in flight). It explodes at the target:

```
/c local p=game.player.position game.player.surface.create_entity{name="artillery-projectile",position=p,target={p.x+300,p.y},speed=0.2,force="player"}
```

While it flies: find every shell, print its position and delete it. If the shell never lands, script can intercept artillery (confirmed 2026-10-17, 2.1.21):

```
/c for _,e in pairs(game.player.surface.find_entities_filtered{type="artillery-projectile"}) do game.print(serpent.line(e.position)) e.destroy() end
```

## Territory brains and bases (territory-brain-plan.md)

Every territory has one brain base, built by map gen around the territory's point; the brain stands in the middle. The map check commands need the `ht-map-check` mod (`mods/ht-map-check` junction to `tools/ht-map-check`, debug runs only).

GPS link to the nearest brain base (click it to open the map there):

```
/ht-map-nearest
```

Check territories and brain bases within 1500 tiles of you (generated chunks only). Prints a summary and writes `script-output/map-check-ingame-result.txt`:

```
/ht-map-check
```

How many brains were moved onto their base (and how many of those moved onto land because their point is on water, ring2-challenge R2-E1 4b), how many territories started claimed (no land at all), how many bases regrow, districts, and GPS links to the guaranteed uranium patches (ring2-challenge R2-E1 4d; "waiting" until the district's chunks are generated):

```
/ht-brains
```

Teleport 120 tiles in front of the nearest standing district heart (spawn side; ring2-challenge 4e1 / 4e1b war): its garrison is on the map, you're just outside its 80-tile zone of control. Run `/ht-goto-ring 2` first so the districts are built:

```
/c local p=game.player.position local best,bd for id,st in pairs(remote.call("hostile-territory-debug","districts_state")) do for _,d in pairs(st.list) do if d.built and not d.fallen then local q=(d.x-p.x)^2+(d.y-p.y)^2 if not bd or q<bd then best,bd=d,q end end end end if not best then game.print("No built district yet: /ht-goto-ring 2 first.") return end local l=math.max(math.sqrt(best.x^2+best.y^2),1) local w={best.x-best.x/l*120,best.y-best.y/l*120} game.player.teleport(game.player.surface.find_non_colliding_position("character",w,10,1) or w) game.print(string.format("District %d [gps=%d,%d]",best.slot,best.x,best.y))
```

Wars (ring2-challenge 4e1 / 4e1b): per territory at war its age, running district fights and fallen districts (GPS), then the garrisons on the map with their unit count; the same line is part of `/ht-brains`:

```
/c game.print(remote.call("hostile-territory-debug","brains"):match("Wars:.*"))
```

Fill the garrison of the nearest live district (within 300 tiles) to full now (ring2-challenge 4e1b; 80 units, ~40 % brutes):

```
/ht-garrison-fill
```

Districts of the nearest ring-2+ base (ring2-challenge R2-E1 4c): GPS link per district heart, built or waiting for its chunks:

```
/c local p=game.player.position local best,bd for id,st in pairs(remote.call("hostile-territory-debug","districts_state")) do for _,d in pairs(st.list) do local q=(d.x-p.x)^2+(d.y-p.y)^2 if not bd or q<bd then best,bd=st,q end end end if not best then game.print("No districts planned yet.") return end for _,d in pairs(best.list) do game.print(string.format("District %d [gps=%d,%d] %s",d.slot,d.x,d.y,d.built and "built" or "waiting for chunks")) end
```

Bases moved onto land (point on water → land spot), with GPS links to the point and the spot:

```
/c for k,m in pairs(remote.call("hostile-territory-debug","brain_state").moved) do game.print(string.format("cell %s: point [gps=%d,%d] -> base [gps=%d,%d] %s",k,m.point.x,m.point.y,m.spot.x,m.spot.y,m.done and "built" or "waiting for chunks")) end
```

Generate and chart 2560 × 2560 tiles around spawn, to see all bases on the map (takes a while):

```
/c local s=game.player.surface s.request_to_generate_chunks({0,0},40) s.force_generate_chunk_requests() game.player.force.chart(s,{{-1280,-1280},{1280,1280}})
```

List every brain (and wyrm) with its position and AI state:

```
/c local t={} for k,v in pairs(defines.segmented_unit_ai_state) do t[v]=k end for _,u in pairs(game.player.surface.get_segmented_units()) do local h=u.segments[1].position game.print(string.format("%s [gps=%d,%d] %s",u.prototype.name,h.x,h.y,t[u.get_ai_state().type])) end
```

Spawn a small brain 25 tiles east of you, without a territory (`hf-brain-medium`, `hf-brain-big` for the others):

```
/c local p=game.player p.surface.create_segmented_unit{name="hf-brain-small",position={p.position.x+25,p.position.y},force="enemy"}
```

Run 10 regrowth rounds now (normally one piece per base per minute); prints how many pieces were built:

```
/c game.print(remote.call("hostile-territory-debug","regrow",10))
```

What a lost crusade does, without the crusade: a brain where you stand (in the territory there), its base grows around it. Step aside first, pieces can't go where you stand:

```
/c local p=game.player.position game.print(remote.call("hostile-territory-debug","place_brain",math.floor(p.x)+0.5,math.floor(p.y)+0.5))
```

Where a crusade on territory 12 would stage (id from `/ht-territory`; may generate a neighbour's base):

```
/c game.print(serpent.line(remote.call("hostile-territory-debug","staging_for",12)))
```

The map-gen layout tests (hive-layout-plan.md L1–L4) live in `tools/ht-layout-test/` and are no longer linked into `mods/`; their commands (`/ht-layout-*`) are gone from normal runs.
