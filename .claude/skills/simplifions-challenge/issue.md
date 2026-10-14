# What an issue holds

Read by `/simplifions-challenge` before it persists a verdict, and by any session that opens a ticket. The reader is the one of `simplifions-commit/readers.md`: a non-technical teammate, in plain words, one screen.

The issue says what must be true when it is done, never how to get there: the author, or an agent, finds the how. Its acceptance lines are what `/simplifions-review`'s asked pass checks the change against, line by line (`simplifions-review/asked.md`); an issue without them leaves the review nothing to check but the plan, which is the author's own reading.

```
[Why: the job the user is trying to get done, one or two sentences]

Acceptance
- [when <situation>, <what the user sees or what the data holds>]
- ...

Limits
- [does not <behaviour> / <thing> stays as it is]

[Bug only]
Reproduce
1. [step, as a role, on a screen]
2. [step]
Result: [what happens]
Expected: [what should]
```

- One acceptance line is one behaviour someone can check by using the app or reading the data. « Works well » is not a line.
- No file, class or method names, no solution: the same rule as a review finding (`simplifions-review/output.md`).
- An issue written by someone else (a PO, a teammate) is never rewritten. The lines it lacks are added under a heading of their own, « Critères ajoutés au challenge », once the user has agreed to them.
