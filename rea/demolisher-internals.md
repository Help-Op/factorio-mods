# Demolisher (segmented-unit) engine internals

Source: `factorio.exe` + shipped `factorio.pdb` (both dated 2026-10-15).
Status: **symbol map only** — function bodies not yet decompiled.
Everything below comes from mangled symbol names in the PDB. These are
observations about what exists, not about what the code does.

## Class layout (from symbol names)

| Class | Role (inferred from method names) |
|---|---|
| `SegmentedUnit` | The entity itself: `update`, `draw`, `die`, `save`, `postSetup` |
| `SegmentedUnitController` | Owns health, force, territory link, activity mode; per-tick `update`; reacts to territory changes |
| `SegmentedUnitAI` | Behaviour state machine; picks a destination and speed |
| `SegmentedUnitNavigation` | Turns a destination into actual movement (turning radius, safe zones) |
| `SegmentedUnitTerritory` | Territory chunks and patrol path generation |
| `SegmentedUnitPrototype` | Prototype data (attack parameters, `FullyExtended` enum) |

## AI states (`SegmentedUnitAI::*` nested structs)

`Patrolling`, `Investigating`, `Attacking`, `DamageTaken`, `Enraged`,
`EnragedAtTarget`, `EnragedAtNothing`. Transitions go through `computeNextState`.

Related methods:
- Patrol: `nearestPatrolWaypoint`, `nextPatrolWaypoint`, `calculatePatrolDestinationTolerance`
- Disturbance detection: `maybeScanForDisturbanceOrAggravator`, `scanTerritoryForDisturbanceToInvestigate`, `scanForNearbyEnemyToAttack` (`ScanType` enum)
- Aggro: `maybeEnrage`, `attackTargetDidAttackUs`, `chooseEnragedAtNothingDestination`, `shouldPrioritize`, `isValidAttackTarget`, `isValidEnemy`
- Outputs consumed by navigation: `getTargetDestination`, `getTargetDestinationTolerance`, `getTargetSpeed`, `getAttackTarget`
- `updatePerMovement` (AI hook called during movement)

## Navigation (`SegmentedUnitNavigation`)

Modes (nested structs): `Direct`, `Away`.

- `getIntendedMovement`, `getIntendedMovementToTarget`: steering toward the destination
- `calculateDistanceFromNearestTurningRadiusCenter`: suggests a turning-circle steering model, not grid A* pathfinding
- `isInSafeZone`, `destinationIsInSafeZone`: the "Away" mode probably steers out of safe zones (not verified)
- `moveUnit`, `moveUnitUntilFullyExtended`: apply movement, including the initial uncurling of segments

**Inference (unverified):** no `PathFinder`/`requestPath` symbols appear under
these classes, so demolishers seem to steer kinematically toward waypoints
with a turning radius rather than calling the engine's unit pathfinder.

## Territory (`SegmentedUnitTerritory`)

`getLocalTerritoryPatrolWaypoint`, `flipIfCounterclockwise`,
`setGeneratedTerritory`, `TerritoryType` enum. The controller reacts to
`onTerritoryChunksChanged`, `onTerritoryPatrolPathChanged`, and `onTerritoryToBeDeleted`.

## Next step

Decompile `SegmentedUnitNavigation::{update,getIntendedMovement,getIntendedMovementToTarget,moveUnit}`,
`SegmentedUnitAI::{computeNextState,getTargetDestination,nextPatrolWaypoint}`, and
`SegmentedUnitTerritory::getLocalTerritoryPatrolWaypoint`. This needs a decompiler
backend (Ghidra 12.1.x for REA).
