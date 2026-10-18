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
| `/cheat-kit <name>` | Tier kit, no armor: `pistol`, `smg-yellow`, `smg-red`, `smg-uranium`, `shotgun`, `flamethrower`, `rockets` |
| `/cheat-clear` | Bare character: no armor, guns, ammo, items or health bonus |

Map setting **Give the demolisher kit on spawn** (Settings → Mod settings → Map), default off.

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

How many brains were moved onto their base, how many territories started claimed (water), how many bases regrow:

```
/ht-brains
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
