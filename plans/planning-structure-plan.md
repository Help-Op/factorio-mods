# Planning structure

> **Status:** Built 2026-10-17, in use · **Parent:** none (workspace meta) · **Next:** first inbox triage · [Roadmap](roadmap.md)

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

## Rules

- **Source of truth:** the plan files. The roadmap is a summary and must never hold a decision that isn't in a plan.
- **When a plan's status changes**, update its header line and its roadmap row in the same edit.
- **Inbox triage:** when a step is done, or when the inbox gets long. Each idea goes to a plan (with a link back), to "Parked" in the inbox, or is dropped.
- **New plan file:** add it to the roadmap table and diagram, with a header line.

## Steps

- [x] 1. Write this plan (2026-10-17).
- [x] 2. Create `roadmap.md` from the current plans (2026-10-17).
- [x] 3. Create `inbox.md` (2026-10-17).
- [x] 4. Add the header line to every plan (2026-10-17).
- [x] 5. Update CLAUDE.md: replace the plan table with a link to the roadmap, add the inbox/roadmap workflow (2026-10-17).
- [ ] 6. User review: does the roadmap help? Adjust the format if not.
- [ ] 7. First inbox triage, once there are a few ideas.

## Open questions

- Should the stale plans (`nauvis-territories-plan.md`, `overlay-debug-report.md`) move to `plans/archive/`? (Roadmap issue R1.)
