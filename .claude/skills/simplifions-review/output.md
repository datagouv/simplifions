# Output format

The review is one list of findings, every one proven (`SKILL.md` § Rules), ranked by severity, most severe first. Its reader is the author or the next agent. Each finding says what is wrong; it may end with one sentence of direction in plain words (« Moving the rule into the model would solve it »), never code: a way to go, not the fix. A visual direction, pointing to a screen the site already shows (« comme sur les pages « modifier » »), comes with a capture of that screen taken with `simplifions-verify`, its local path given: the user attaches it to the comment by hand.

## Severity

- **critical**: breaks production, data or security.
- **important**: a visitor or an admin will hit it, or the next feature of the same kind will pay for it. Every `ask` row is at least important, and so is a new code path no test exercises.
- **minor**: debt, simplicity, a test gap on a tested path, a detail.

## Type

One of: `ask` (a line of the ask missing, deviating or unclear, or an extra that crosses a limit), `bug`, `test`, `design`, `simplicity`, `readability`, `rule` (a written rule the diff breaks), `pre-existing` (a bug in code the diff did not change).

## Constat

Written for the PR's author, who may be the product owner, not a developer: one or two sentences of 20 words at most, in French and in the site's own words (démarche, solution, cas d'usage, brouillon…), naming the behaviour, who meets it (a visitor, an admin, a developer) and when. A finding that only exists in the code (a missing index, an unrelated reformatting) names the page, the data or the change it touches. A `rule` row quotes the rule. File paths and code names live on the `Where:` line of § Details only.

## Verdict

From the findings, `pre-existing` left out; the first that matches: `needs rethink` (the ask is `off-target`, or a critical or important `design` row questions the approach itself), `fix first` (a critical or important row), `clean up first` (a minor one), `ship it`.

## Report

Constats and bracketed text in French. Labels, type, severity and verdict words, the `Ask:` marks and `not run` stay in English as written here: `/simplifions-ship` reads them. A link is always whole (a PR, an issue, a URL). A section with nothing in it is left out.

```
## Code Review: [PR title or branch] — [verdict]
Author: [PR author login, or the branch owner] · Model: [the model this review ran on] · Head: [the commit SHA reviewed]
Ask: [SIM-ID and title, "no source found", or "not run — <reason>"] — delivered | partial | off-target
Drive: [the evidence path under tmp/verify/ of each drive]
Note: [what the review could not check: a feature not driven, an issue not pasted]

### Findings
| # | Severity | Type | Constat |
|---|---|---|---|
| [n] | [critical / important / minor] | [type] | [constat, then its direction sentence if any] |

### Details
[n]. [the line of finding n's type, below]
```

Details item N is finding N, in the line of its type:

- `bug`, `test`, `pre-existing`: `Reproduce: [steps] · Result: [what happens, against what should] · Class: [the kind of bug, when the diff holds several instances] · Where: [path:line, path:line]`
- `design`: `[who decides or holds what today] · [who should] · [what disappears if it moves] · Where: [path:line]`, the first three in plain words, no code names
- `simplicity`, `readability`: `[what it costs] · Where: [path:line]`
- `rule`: `[the rule, quoted] — [its file] · Where: [path:line]`
- `ask`: `[the ask line] — missing | deviates: [how] | extra: [the limit it crosses] · Result: [what the visitor gets] · Decision: [what the product owner decides]`, or `[the ask line] — unclear: [what would settle it]`

A finding with a visual direction ends its line with `· Capture: [the capture's local path]`.

## To paste on the PR

When the user asks for the review on a PR, give one block of text, all in French, labels translated, for them to paste as a comment on the PR's page (full link given with it); the agent itself posts nothing. Its content:

- `**[verdict]** · commit [short SHA]`, then the ask on its own lines: when the `Ask:` line carries a mark (`no source found` and `not run` carry none), `Demande : https://linear.app/pole-api/issue/SIM-<n>` and `Demande réalisée : oui | non | partielle` (from `delivered | off-target | partial`); when the report has a `Note:`, `Commentaire : [the Note:, as the review's own limit, never as a gap of the PR]`.
- The findings table (sévérité, type, constat alone).
- For each row with a direction, or a `bug` or `test` row: its number, `Piste de correction : [the direction]` when it has one (a visual one followed by its capture's path), and for a `bug` or `test` one `Reproduire :` line with the steps only (the constat already says the result) and the `path:line` where it starts.
