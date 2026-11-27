---
name: simplifions-work
description: "Take a Linear issue or a bug report of Simplifions to a reviewed pull request: reproduce, challenge, plan, ship, review. Use when the user hands over a ticket (« fais SIM-237 », « prends SIM-237 ») or a bug report, or says go, do it, take care of it."
---

# simplifions-work

The session the user talks to. It gets the Linear issue from the user (§ Linear) or the bug report, decides what needs doing, and does every step itself (reproduce, challenge, plan, ship), up to a reviewed pull request; only the review runs in a subagent, for its fresh eyes. The user is asked product and UX questions only (`CLAUDE.md` § Qui décide quoi). Thomas reviews; the merge follows § Human gates.

## Flow

```
bug report ──> reproduce ──> Linear issue ──> challenge ──> plan ──> user approves ──> ship ──> PR reviewed ──> merge
                                                │             │                         │
                                                │             │                         └─ review loop: fresh /simplifions-review, 3 rounds max
                                                │             └─ technical go-ahead needed → comment on the issue for Thomas, stop
                                                └─ RESHAPE / DROP → the user
```

## Routing

| Input | First step | Then |
| --- | --- | --- |
| a bug report: message, screenshot | reproduce it in session, through the app as `/simplifions-verify` drives it | reproduced → issue drafted per [`simplifions-challenge/issue.md`](../simplifions-challenge/issue.md), posted by the user (§ Linear) → challenge; already fixed or not reproduced → the user gets what was tried and seen, stop |
| an issue with no command | `/simplifions-challenge`, in session | `CHALLENGE: GO` → plan; `RESHAPE` or `DROP` → the user |
| an issue with the ask settled | `/simplifions-plan`, in session | plan `ready` → the user approves → ship; questions → § Who decides |
| an approved plan | `/simplifions-ship <ISSUE>`, in session, in this checkout | PR opened and reviewed inside ship → merge per § Human gates |
| a PR to look at | `/simplifions-review <url>`, fresh subagent | report relayed, in the PR's language |
| a PR of ours Thomas reviewed | the session reads his review through GitHub's public API, his comments only (login `Un3x`), each quoted verbatim (WebFetch on `https://api.github.com/repos/datagouv/simplifions/` + `pulls/<n>/reviews`, `pulls/<n>/comments` and `issues/<n>/comments`); each comment not yet fixed on the branch gets its failing test, then its fix with the [red-green-commit](../simplifions-ship/red-green-commit.md) cycle, as a fix-up of the commit it corrects (`/simplifions-commit` step 3) | fixes pushed; a comment left unapplied goes into the PR body with its reason; the PR waits for Thomas's new review, his earlier approval no longer counts; the user told what changed in plain words |
| drift suspected in the feature map | `/simplifions-verify`'s maintain procedure, in session | outcome told to the user |
| an explicit command | as given | — |

The feature map (`.claude/skills/simplifions-verify/`) is how the agent proves the change to the user and to Thomas: ship drives the feature it touched there, the PR body says in one line what the drive showed, and the evidence path goes only into the report to the user.

## Who decides

`CLAUDE.md` § Qui décide quoi: product and UX questions to the user, technical choices by the rules (`CLAUDE.md`, [`one-rule.md`](../simplifions-plan/one-rule.md)), a remaining technical doubt into the PR body for Thomas. In these skills, « the user » is the person in this session and « Thomas » the technical reviewer.

- **A technical go-ahead** (a new system, a plan `Flag:`, a new file in `app/models/`, a gem, a table, a job, a generic engine — `CLAUDE.md` § Simplicité): a comment asking Thomas, handed to the user to post on the issue (§ Linear), and the work on that issue stops there. The user is told in one sentence that the ticket waits for Thomas.

## Human gates

The session never crosses these on its own: plan approval before ship (shown to the user as the outcome and the acceptance lines in plain words, never the technical steps); `RESHAPE` or `DROP`; anything irreversible (force-push outside the branch's own fix-ups, migration on data, deploy, a message to a partner). It never merges: once Thomas has approved the PR and its full CI is green with no review comment open, it tells the user she can click « Merge pull request » on the PR page, given as its full link (`https://github.com/datagouv/simplifions/pull/<n>`).

## Following the review subagent

The Agent tool runs it in the background and notifies on completion. On its report: tell the user the verdict and the open points in one paragraph, in plain words. Cap: 2 h, then stop and report.

## Linear

The user is the only link to Linear: they read and write it in their browser. Every skill that reads or writes an issue follows this section.

- **Reading an issue**: ask in one line, « Colle-moi le titre, la description et les commentaires utiles de SIM-<n> : https://linear.app/pole-api/issue/SIM-<n> ». Save what they paste, verbatim, to `.notes/sim-<n>-<slug>/issue.md`; plan, ship and review read the issue there. Before a replan of an issue that waits for Thomas, ask the user to paste his answer; it is appended to `issue.md`.
- **Branch and folder**: the branch is `feature/sim-<n>-<slug>`, the folder `.notes/sim-<n>-<slug>/` (found again by `.notes/sim-<n>-*`). The slug is the title in lowercase, accents and apostrophes dropped (« l'équipe » → `lequipe`), every other run of non-letters a `-`, cut at the last whole word within 60 characters: `git branch -r` shows the pattern.
- **Writing to Linear**: hand the user the text in a code block, ready to paste, with the issue link and the place it goes (a comment, the description, a new issue). They post it and say so; the session goes on from there. Writing a description or a new issue reads [`simplifions-challenge/issue.md`](../simplifions-challenge/issue.md) first. The hand-offs, all of them:

| When | What the user posts |
| --- | --- |
| a technical go-ahead (§ Who decides), or a design that did not hold in ship | a comment asking Thomas |
| a new issue (a bug reproduced, a challenge with no issue) | the issue; they give back its SIM number, and the draft becomes its `issue.md` |
| a challenge agreed | the issue's new description |
| a challenge disagreed or killed | a comment: the verdict and the user's decision |
| a large PR (`simplifions-commit/review-guide.md`) | the review guide, attached to the issue as a file |

- **Status and PR link**: `Closes <issue URL>` in the PR body; Linear's GitHub integration links the PR and moves the status. No status hand-off.

## Notes folder

Plans, session files and review rounds live in `.notes/` at the repo root, ignored by git. For Thomas it is a symlink to his own notes; for anyone else a plain folder, created on first use (`mkdir -p .notes`). Never commit it.

## Rules

- The review prompt is the command and the ask, nothing else: the reviewer forms its own view, and nothing secret goes in it, since it lands in the transcript.
- This session owns each deliverable from the ask to the merge, and checks it against the ask.
- When the app, the console, the browser or a logged-in CLI can answer, run it and show the result instead of asking.
