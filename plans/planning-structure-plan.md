# Planning structure

> **Status:** In use; rules now shared with CampCore as user skills (PS7, 2026-11-22) · **Parent:** none (workspace meta) · **Next:** pick a Working towards milestone (PS-Q1) · [Roadmap](roadmap.md)

## Goal

Make the big picture easy to follow while new ideas keep coming in.

- Capture random thoughts with no friction, without growing the active plans.
- One short page that shows where everything stands and how the plans connect.
- CLAUDE.md says **how** we work in this project, not **what** we work on.

## Decisions (user, 2026-10-17)

| # | Topic | Decision |
|---|-------|----------|
| PS1 | Random thoughts | `plans/inbox.md`: one dated line per idea, no sorting. Triaged together later. |
| PS2 | Big picture | `plans/roadmap.md`: one screen, status per plan, dependencies, Mermaid diagram. |
| PS3 | Plan headers | Every plan starts with one status line: Status · Parent · Next. The roadmap summarises these. |
| PS4 | CLAUDE.md | The plan table moves to the roadmap. CLAUDE.md keeps workflow, conventions, layout, gotchas, and explains the inbox/roadmap flow. |
| PS5 | Visual | Mermaid in `roadmap.md` (VS Code preview, GitHub). No Miro: second source of truth, drifts, not versioned. |
| PS6 | Fog and out of scope (2026-10-17) | Two roadmap sections, borrowed from the wayfinder skill: **Not yet specified** (known unknowns that aren't a clear question yet) and **Out of scope** (decided not to do, marked "for now" or "no"). Wayfinder itself not adopted: it moves decisions into GitHub issues and is built for one destination. |

## Decisions (user, 2026-11-22): one shared process with CampCore

CampCore copied this structure on 2026-10-29 and improved it through retros; this workspace stayed as it was. Decided and recorded in CampCore's `plans/planning-structure-plan.md` (PS6–PS10).

| # | Topic | Decision |
|---|-------|----------|
| PS7 | Shared process | The rules live in user skills: `planning` (plans, roadmap, inbox, header line, sync at thread boundaries, Working towards), `dispatch` (with the Play hand-over shape this workspace started), `retro`, `writing-for-agents`. "How we work" moved to the global `~/.claude/CLAUDE.md`. Here: the header rule and hook (`~/.claude/hooks/plan-headers.sh`), sync at thread boundaries, a Working towards milestone, `/dispatch` and `/retro`. Branch runs and tests-first stay CampCore-only for now |

## Rules

The rules live in the `planning` user skill (`~/.claude/skills/planning/SKILL.md`). Changes from the original rules here (2026-10-17):

- **Roadmap sync at thread boundaries**, not on every status change (CampCore retro, 2026-10-30).
- **Header line holds the current state**, rewritten, never appended to; the hook refuses one over 400 characters (CampCore retro, 2026-11-01). On 2026-11-22 the oil-ring, ring-2 and ring-feel headers (up to 4,300 characters) were rewritten; their old text sits at the end of each plan.
- **Working towards** and **Done threads** at the roadmap's top (CampCore, 2026-10-30 and 2026-11-04).

## Steps

- [x] 1. Write this plan (2026-10-17).
- [x] 2. Create `roadmap.md` from the current plans (2026-10-17).
- [x] 3. Create `inbox.md` (2026-10-17).
- [x] 4. Add the header line to every plan (2026-10-17).
- [x] 5. Update CLAUDE.md: replace the plan table with a link to the roadmap, add the inbox/roadmap workflow (2026-10-17).
- [x] 5b. Add Fog and Out of scope sections to the roadmap (PS6, 2026-10-17).
- [x] 6. User review: "Format helps for sure" (user, 2026-10-17).
- [ ] 7. First inbox triage, once there are a few ideas.
- [x] 8. Adopt the shared process (PS7): CLAUDE.md points to the skills, `.githooks/pre-commit`, over-long headers rewritten (2026-11-22).
- [ ] 9. Enable the hook (`git config core.hooksPath .githooks`) and pick the milestone (PS-Q1).

## Open questions

- **PS-Q1**: Which milestone goes in the roadmap's *Working towards*? Picked by the user at the next thread boundary.
- **PS-Q2**: Move the mod sections of CLAUDE.md into an `ARCHITECTURE.md`, as in CampCore?
