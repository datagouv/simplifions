# Output format

The report says what is wrong and how to see it, never how to fix it. Its reader is the author or the next agent, who finds the code and the fix on their own: a finding is a behaviour, the steps that reproduce it, and the result. No `file:line`, no class or method names, no « Fix: » line (Passemarche PR #562, 2026-10-09: the findings were right, Thomas rewrote every one before posting). A finding that only exists in the code (a missing index, an unrelated reformatting) names the screen, the data or the change it touches in plain words.

The report is written in the language of the PR (title, commits, description), whatever language the session runs in: it is relayed to the team as is (2026-09-18 Passemarche, 2026-09-21 Apistration: two reports rewritten in French on request).

A section with nothing in it is left out. The data flow diagram of step 7 is a working tool, not part of the report.

```
## Code Review: [PR title or branch] — [verdict: ship it / fix criticals first / simplify first / needs rethink]
Author: [PR author login, or the branch owner] · Model: [the model this review ran on]

### ASKED vs BUILT
Ask: [ISSUE-ID and title, or "no source found"]
- [line of the ask] — delivered ([the test or scenario that proves it]) | missing | deviates: [how] | unclear: [what would settle it] | unproven
Extra: [what the change does that no line asked for, and the limit it crosses if any]
Verdict: delivered | partial | off-target

### CRITICAL (must fix)

**1. [The wrong behaviour, in one sentence]**
Reproduce:
1. [step]
2. [step]
Result: [what happens, against what should]

### DESIGN

**1. [Who decides or holds what today, and who should, in plain words]**
[What disappears if it moves: a second path, a list, a copy]

### SIMPLICITY (over-engineering)

**1. [What is heavier than it needs to be]**
[What it costs]

### CODEX SECOND OPINION
Confirmed: [findings Codex raised that you verified and did not have, written like the ones above]
Rejected: [finding — why]
(or: "not run — <reason>"; agreements are tagged "(also Codex)" on your own finding and need no line here)

### INFORMATIONAL (worth knowing)

**1. [What to know, in one sentence]**
[When it shows up, and who it affects]
```
