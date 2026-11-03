# Ship session file and resumption

Progress lives in `.notes/<branch_name>/ship-session.md`, so it survives compaction and restarts, and two ships never share it. Read it first to reorient yourself.

```markdown
# Ship SIM-124
Started: YYYY-MM-DD HH:MM
Status: in-progress
Phase: implement
Plan step: 3/5
Review round: 0

## Pull request

## Notes
```

Status: `in-progress`, `shipped` (branch pushed, review loop finished clean or cap reported), `skipped` (the plan has questions or a `Flag:`), `blocked` (no proof, or a design that does not hold; reason in Notes), `failed` (error, reason in Notes).

Phases: `setup` → `implement` → `push-pr` → `review` → `done`

## Resumption

`/simplifions-ship` with no args: scan `.notes/*/ship-session.md` for Status `in-progress`. Several: report the list and stop; the session that spawned you reruns `/simplifions-ship <issue>`. One: switch to its branch and continue from its Phase:
- `implement`: from its Plan step
- `review`: read the latest `.notes/<branch_name>/review-round-N.md`; open findings (`review-loop.md`) → resume the fix cycle; none → spawn the next review subagent
