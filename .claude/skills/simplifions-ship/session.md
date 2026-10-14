# Ship session file and resumption

All progress is persisted in `.notes/_ship-session.md` so work survives context compaction or session restarts. Always read the session file first to reorient yourself.

```markdown
# Ship Session
Started: YYYY-MM-DD HH:MM

## Issues
- [x] SIM-123 - shipped (PR: #123, review clean round 2)
- [>] SIM-124 - in-progress (step: implement, plan-step: 3/5)
- [ ] SIM-125 - pending
- [-] SIM-126 - skipped (has questions)
- [!] SIM-127 - failed (test failures)

## Current
SIM-124

## Current Phase
implement

## Notes
SIM-127: RuntimeError in the Grist import - needs investigation
```

Status markers:
- `[ ]` pending - not yet started
- `[>]` in-progress - currently being shipped
- `[x]` shipped - PR created and review loop finished clean
- `[-]` skipped - has questions or intentionally skipped
- `[!]` failed - error during shipping

Phases: `setup` → `post-plan` → `implement` → `push-pr` → `review` → `done`

## Resumption

When resuming (via `/simplifions-ship` with no args):
1. Read `.notes/_ship-session.md` to understand current state
2. Find the `## Current` issue and `## Current Phase`
3. For `implement` phase: also read `.notes/<branch>/implement-plan.md` to find current step
4. For `review` phase: read the latest `.notes/<branch>/review-round-N.md` — unfixed findings → resume the fix cycle; all fixed → spawn the next review subagent
5. Continue from that exact point

This works even after:
- Context compaction (conversation summarized)
- Session restart (new Claude Code session)
- Interruption (user closes terminal)
