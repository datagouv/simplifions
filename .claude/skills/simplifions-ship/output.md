# Output templates

### When resuming:
```
Resuming ship session (started YYYY-MM-DD).
Progress: 3/10 issues shipped, 1 in-progress.
Current: SIM-124 (phase: implement, step 3/5)

Continuing implementation...
```

### After each issue ships:
```
Shipped SIM-124 -> PR: https://github.com/org/repo/pull/124 (review clean after 2 rounds)
Continuing with SIM-125...
```

### When the review cap is hit:
```
SIM-124 -> PR: https://github.com/org/repo/pull/124 — 3 review rounds done, findings still open:
  - [finding]
Session saved. Open findings listed in the PR body for Thomas.
```

### When batch complete:
```
Shipping complete.

Shipped:
  SIM-123 - title -> PR: https://github.com/org/repo/pull/123
  SIM-124 - title -> PR: https://github.com/org/repo/pull/124

Skipped (has questions):
  SIM-125 - title (run /simplifions-plan SIM-125 to resolve)

Failed:
  SIM-126 - title (error: reason)
```

### On error:
```
Error shipping SIM-126: [error details]

Session saved. Run `/simplifions-ship` to retry this issue or continue with remaining.
To skip this issue: manually mark as skipped in .notes/_ship-session.md
```
