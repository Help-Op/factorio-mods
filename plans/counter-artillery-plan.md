# Counter-artillery

> **Status:** Interview, nothing built · **Parent:** roadmap fog "Counter-artillery", after [territory-brain-plan.md](territory-brain-plan.md) · **Next:** answer open questions, then CA1 fire-event test · [Roadmap](roadmap.md)

## Goal

Strong hives defend against player artillery. Counter units shoot player shells mid-flight. Each unit recharges between shots, so enough artillery still wins. How many units a territory has depends on its challenge level. The player learns the count by scouting.

## Decisions (user, 2026-10-17)

| # | Decision |
|---|----------|
| CA-D1 | **Interception:** fire a visible counter shell timed so both shells are as close as possible at impact, with an explosion there. Close enough is fine: the shot being fired is what counts, the incoming shell is destroyed either way |
| CA-D2 | **Detection:** react to a fire event, not a periodic surface scan (see CA-F2 for which event) |
| CA-D3 | **Unit type:** worm-like turret building, or a huge, very slow unit with only long range and no melee. CA-D6 favours the unit |
| CA-D4 | **Stats:** about equal to vanilla artillery (range, shell speed). Recharge **30 s** to start. Pollution may upgrade it, very slowly |
| CA-D5 | **Count:** set by challenge level (distance, evolution), tuned by testing. Also allow a few **templates** (e.g. no counters, few strong, many weak) |
| CA-D6 | **Brain dead → counter units go dormant** (stop intercepting), not destroyed |
| CA-D7 | **Crusades:** counter units can join a crusade. One of the few places where they attack, not only defend |
| CA-D8 | **Feedback:** the counter shell shows as a dot on the map like a player shell. Both dots vanish once stopped. Optional alert, opt-in (per-player setting) |

## Confirmed facts

| # | Fact | Source |
|---|------|--------|
| CA-F1 | `artillery-projectile` has no health; only script can remove it. `find_entities_filtered{type="artillery-projectile"}` finds shells in flight (two at once too), `destroy()` removes them with no explosion at the target | in game, 2.1.21, 2026-10-17 |
| CA-F2 | `on_trigger_fired_artillery` exists, but only for capsule triggers with `trigger_fired_artillery=true` (the artillery flare), **not** for turret or wagon fire. Candidate instead: add a `script` effect to the shell ammo's `source_effects` → `on_script_trigger_effect` at fire time with `source_entity` (turret/wagon) and `target_position`. Untested | `runtime-api.json` 2.1.21 |

## Issues

- Fire event only gives turret + target, not the projectile. Script must then find the new shell (`find_entities_filtered` near the turret, same or next tick) to know its flight time.
- Other mods' artillery ammo would need the same `source_effects` patch (data-final-fixes, all `ammo` with `artillery` delivery).

## Steps

- [ ] **CA1** Fire-event test (test mod in `tools/`): patch `source_effects` with a `script` effect, fire a turret and a wagon, log the event and whether the shell entity can be found that tick
- [ ] **CA2** Flight-time maths: measure shell speed and flight time over a known distance; compute the meeting point and when to launch the counter shell
- [ ] **CA3** Counter shell prototype (HF): enemy `artillery-projectile` with map dot, impact explosion, no ground damage
- [ ] **CA4** Counter unit prototype (HF): slow segmented unit or worm-like turret (decide after Q1), 30 s recharge
- [ ] **CA5** Intercept script (HT): fire event → pick a ready counter unit in range → launch counter shell → destroy player shell at meet time
- [ ] **CA6** Count by challenge level + templates, place in the brain base
- [ ] **CA7** Dormant on brain death
- [ ] **CA8** Crusade participation
- [ ] **CA9** Opt-in alert setting
- [ ] **CA10** In-game feel test, tune recharge and counts

## Open questions

1. **Unit vs building (CA-D3, CA-D6):** go with the slow unit? A dormant segmented unit already stands still and fights back (EB3c C1). Is its long-range attack aimed at buildings, units, or only shells?
2. **Range test:** is "in range" measured to the player turret, to the meeting point, or to the target? (Vanilla range is easy to reach with research upgrades.)
3. **Several shells, several units:** one counter unit per shell, nearest ready unit first? Shells aimed outside the territory are ignored?
4. **Pollution upgrade (CA-D4):** what does it improve (recharge, range), and how slow is "very slowly"?
5. **Templates (CA-D5):** link to the army templates idea (roadmap "Later: templates"), or a separate list?
6. **Crusade role (CA-D7):** what does a counter unit attack during a crusade: player artillery, turrets, anything in range? Does it travel with the crusade at its slow speed?
7. **Alert (CA-D8):** a per-player mod setting, default off?
