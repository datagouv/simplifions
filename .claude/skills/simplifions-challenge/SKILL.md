---
name: simplifions-challenge
description: "Question whether and what to build before planning a Simplifions issue. Run before /simplifions-plan."
---

Challenge command. Forces a "are we building the right thing?" pass before engineering work.

## Usage
- `/simplifions-challenge <issue1> <issue2> ...` - Challenge listed issues (IDs or URLs)
- `/simplifions-challenge` (no args) - Challenge the current conversation topic

## Purpose

This is the **founder brain** — not engineering, not planning, not review. The goal is to pressure-test whether we're solving the right problem before writing any code.

Run this BEFORE `/simplifions-plan`. Planning locks in HOW to build. This questions WHETHER and WHAT to build.

## Behavior

With issue arguments: read each issue from Linear ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)), run the challenge framework on each, output findings per issue. Without arguments: ask the user what they're about to build, then run the framework on their description.

## Challenge Framework

For each feature/issue, think through these in order:

1. **Job-to-be-Done** — What is the user actually trying to accomplish? Is the issue description the real problem, or a symptom? Restate the problem in terms of user outcome, not implementation.
2. **10x Check** — What would a 10x better version of this look like? Are we thinking too small? Too incremental? What would make users genuinely delighted, not just unblocked?
3. **Scope Interrogation** — Is this the minimum that delivers the outcome? What can we cut without losing the core value? What are we including "just in case" that we should drop? Conversely: is there something small we're missing that would 3x the value?
4. **Risk & Reversibility** — Is this a one-way door or two-way door? What's the blast radius if this is wrong? Can we ship a smaller version first to validate?
5. **Opportunity Cost** — What are we NOT doing by spending time on this? Is this the highest-leverage thing right now? Does this compound (builds future value) or is it a one-off?
6. **Split Granularity** (only if recommending a split) — [`slices.md`](slices.md): vertical slices, one-sentence test, one story per PR.

## Output Format

```
## Challenge: [Issue title or topic]

**The real job**: [reframed problem statement]

**10x version**: [what great looks like]

**Scope verdict**: [too big / right-sized / too small / wrong shape]
[specific cuts or additions if any]

**Risk**: [one-way/two-way door, blast radius]

**Opportunity cost**: [what we're trading off]

**Appetite**: [the size the outcome is worth: a morning, a day, a week — /simplifions-plan's size cap takes it]
**Acceptance**: [the lines the issue lacks, shaped by [`issue.md`](issue.md); "already in the issue" when it has them — /simplifions-review's asked pass checks the change against them]
**No-gos**: [what this issue will not do, one line each — /simplifions-review's asked pass reads them as limits]
**Rabbit holes**: [where the work could sink time, and the way around]
**Rejected alternatives**: [what was considered and why not, one line each]

**Recommendation**: [proceed as-is / rethink scope / split into phases / kill it]
[brief rationale; if splitting, name the vertical slices and the one-sentence value of each]
```

## Persist the Verdict

After presenting findings, ask the user whether they agree with the recommendation. Then update the issue so downstream commands (`/simplifions-plan`, `/simplifions-ship`) read the post-challenge truth instead of the original issue:

- **Agreed (proceed / rethink with changes)**: update the issue description in the shape of [`issue.md`](issue.md) — reframed problem, acceptance lines, limits (the no-gos), appetite, spike flag if applicable. An issue someone else wrote gets its missing lines added under their own heading, never rewritten. The description should reflect what we actually decided to build, in the words of `simplifions-commit/readers.md`: why, scope, limits, for a non-technical reader. Rejected alternatives and rabbit holes stay in the challenge output, not on the issue.
- **Last line of every challenge, verbatim**: `CHALLENGE: GO` (proceed as is or with agreed changes), `CHALLENGE: RESHAPE` (split or rethink, the user decides), or `CHALLENGE: DROP`. `simplifions-work` reads that line and nothing else.
- **Disagreed or killed**: leave a comment with the verdict and the user's decision, so the reasoning survives the next time the issue surfaces.
- **No issue** (conversation-mode challenge): offer to create one capturing the agreed scope.

Never update Linear before the user has weighed in.

## Rules

- Be direct. If the idea is bad, say so.
- If the issue is clearly well-scoped and straightforward, say "looks good, proceed to /simplifions-plan" — don't force artificial depth.
- Don't over-engineer the challenge for small tasks. A 1-line bug fix doesn't need a 10x vision.
- The goal is to catch scope mistakes and wrong problems BEFORE we invest in planning.
