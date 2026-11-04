---
name: simplifions-challenge
description: "Question whether and what to build before planning a Simplifions issue. Run before /simplifions-plan."
---

Challenge command. Forces a "are we building the right thing?" pass before engineering work.

## Usage
- `/simplifions-challenge <issue1> <issue2> ...` - Challenge listed issues (IDs or URLs)
- `/simplifions-challenge` (no args) - Challenge the current conversation topic

## Behavior

With issue arguments: get each issue and its comments from the user ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)), run the challenge framework on each, output findings per issue. Without arguments: ask the user what they're about to build, then run the framework on their description.

## Challenge Framework

For each feature/issue, think through these in order:

1. **Job-to-be-Done** — What is the user actually trying to accomplish? Is the issue description the real problem, or a symptom? Restate the problem in terms of user outcome, not implementation.
2. **10x Check** — What would a 10x better version of this look like? Are we thinking too small? Too incremental? What would make users genuinely delighted, not just unblocked?
3. **Scope Interrogation** — Is this the minimum that delivers the outcome? What can we cut without losing the core value? What are we including "just in case" that we should drop? Conversely: is there something small we're missing that would 3x the value?
4. **Risk & Reversibility** — Is this a one-way door or two-way door? What's the blast radius if this is wrong? Can we ship a smaller version first to validate?
5. **Opportunity Cost** — What are we NOT doing by spending time on this? Is this the highest-leverage thing right now? Does this compound (builds future value) or is it a one-off?
6. **Split Granularity** (only if recommending a split) — [`slices.md`](slices.md): vertical slices, one-sentence test, one story per PR.
7. **Screen** — the issue changes what a user sees and shows no screen: the user brings it (a shared Claude artifact, or captures with the intentions that matter), approved before `CHALLENGE: GO`. Asked to draw it, the agent starts from the real content (a full list, an empty one, an error, a long name), the DSFR and the screens next to the one that changes, and captures and looks at every screen at desktop and phone width before showing it.

## Output Format

```
## Challenge: [Issue title or topic]

**The real job**: [reframed problem statement]

**10x version**: [what great looks like]

**Scope verdict**: [too big / right-sized / too small / wrong shape]
[specific cuts or additions if any]

**Risk**: [one-way/two-way door, blast radius]

**Opportunity cost**: [what we're trading off]

**Acceptance**: [the lines the issue lacks, shaped by [`issue.md`](issue.md); "already in the issue" when it has them; a bug's are its steps and expected behaviour — /simplifions-review's asked pass checks the change against them]
**No-gos**: [what this issue will not do, one line each — /simplifions-review's asked pass reads them as limits]
**Screen**: [the mockup the issue links / brought: approved or not / n/a]
**Rabbit holes**: [where the work could sink time, and the way around]
**Rejected alternatives**: [what was considered and why not, one line each]

**Recommendation**: [proceed as-is / rethink scope / split into phases / kill it]
[brief rationale; if splitting, name the vertical slices and the one-sentence value of each]
```

## Persist the Verdict

After presenting findings, ask the user whether they agree with the recommendation. Then hand the user the update to post on the issue, so downstream commands (`/simplifions-plan`, `/simplifions-ship`) read the post-challenge truth instead of the original issue:

- **Agreed (proceed / rethink with changes)**: write the issue in the shape of [`issue.md`](issue.md), from the reframed problem, the acceptance lines, the no-gos and the approved mockup; hand it to the user, ready to paste as the new description; once they have posted it, it replaces the description in `issue.md`. Rejected alternatives and rabbit holes stay in the challenge output, not on the issue.
- **Last line of every challenge, verbatim**: `CHALLENGE: GO` (proceed as is or with agreed changes, once every decision has its answer), `CHALLENGE: RESHAPE` (split or rethink, the user decides), or `CHALLENGE: DROP`. `simplifions-work` reads that line and nothing else.
- **Disagreed or killed**: a comment with the verdict and the user's decision, for them to post, so the reasoning survives the next time the issue surfaces.
- **No issue** (conversation-mode challenge): offer the text of a new issue capturing the agreed scope, for the user to create ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)).

## Rules

- If the idea is bad, say so.
- **Finding facts is your job, never the user's.** A fact the code, the git history or the issue can give is looked up; the user gets product and UX decisions only (`CLAUDE.md` § Qui décide quoi), each with its recommended answer.
- Depth follows the issue: a well-scoped one gets "looks good, proceed to /simplifions-plan", a 1-line bug fix no 10x vision.
