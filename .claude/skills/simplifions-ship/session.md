# Ship session file and resumption

Progress lives in `.notes/<branch_name>/ship-session.md`, so it survives compaction and restarts, and two ships never share it. Read it first to reorient yourself.

```markdown
# Ship SIM-124
Started: YYYY-MM-DD HH:MM
Status: in-progress
Phase: implement
Plan step: 3/5

## Pull request

## Notes
```

Status: `in-progress`, `shipped` (branch pushed, PR opened or its text ready), `skipped` (the plan has questions or a `Flag:`), `blocked` (no proof, or a design that does not hold; reason in Notes), `failed` (error, reason in Notes).

Phases: `setup` → `implement` → `prove` → `review` → `push-pr` → `done`

## Resumption

`/simplifions-ship` with no args: scan `.notes/*/ship-session.md` for Status `in-progress`. Several: report the list and stop; the user picks one and reruns `/simplifions-ship <issue>`. One: switch to its branch and continue from its Phase:
- `implement`: from its Plan step
- `prove`: drive again from the start of phase 3
- `review`: `.notes/<branch_name>/review-report.md` there → resume the fix cycle from its `## Triage`; absent → spawn the review subagent
- `push-pr`: from the autosquash
