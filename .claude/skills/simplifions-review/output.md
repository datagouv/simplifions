# Output format

The review is one list of findings, every one proven (`SKILL.md` § Rules), ranked by severity, most severe first. Its reader is the author or the next agent. Each finding says what is wrong; it may end with a direction in a few plain words, when there are two ways joined by « ou » (« Déplacer la règle dans le modèle réglerait le problème »), never code: a way to go, not the fix. A visual direction, pointing to a screen the site already shows (« comme sur les pages « modifier » »), comes with a capture of that screen taken with `simplifions-verify`, its local path given: the user attaches it to the comment by hand.

## Severity

- **critical**: breaks production, data or security.
- **important**: a visitor or an admin will hit it, or the next feature of the same kind will pay for it. Every `ask` row is at least important, and so is a new code path no test exercises.
- **minor**: debt, simplicity, a test gap on a tested path, a detail.

## Type

One of: `ask` (a line of the ask missing, deviating or unclear, or an extra that crosses a limit), `bug`, `test`, `design`, `simplicity`, `readability`, `rule` (a written rule the diff breaks), `pre-existing` (a bug in code the diff did not change).

## Constat

Written for the PR's author, who may be the product owner, not a developer: the risk, not its proof. What can happen, when, and what the visitor, the admin or the developer gets, in one sentence of about 20 words, in French and in the site's own words (démarche, solution, cas d'usage, brouillon…). A finding that only exists in the code (a missing index, an unrelated reformatting) names the page, the data or the change it touches. Product names (the site, a page, the admin, Grist) are welcome; code names (a constant, a field, a method), quotes from the spec or the code, and proof (timings, config, values, error text) go in § Details and in the pasted `Détails` block. The constat of an `ask` row, and of any finding about what the visitor sees, ends on the decision the product owner makes (an `unclear` ask: the question she settles), so she reads it without opening `Détails`. A `rule` row quotes the rule. File paths live on the `Where:` line of § Details. Before handing out the text to paste, reread each constat as the author: a sentence that needs the code to be understood is rewritten.

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
| [n] | [critical / important / minor] | [type] | [constat, then its direction if any] |

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

- `**[Verdict]** · commit [short SHA]`, the verdict translated and starting with a capital letter (« **À corriger d'abord** » ; § Report keeps the English words), then the ask on its own lines: when the `Ask:` line carries a mark (`no source found` and `not run` carry none), `Demande : https://linear.app/pole-api/issue/SIM-<n>` and `Demande réalisée : oui | non | partielle` (from `delivered | off-target | partial`); when the report has a `Note:`, `Commentaire : [the Note:, as the review's own limit, never as a gap of the PR]`.
- The findings, as one table, most severe first:

  ```
  | # | | Constat |
  |---|---|---|
  | [n] | **[Sévérité]**&nbsp;·&nbsp;[type] | [constat] |
  ```

  The severity in French with a capital letter (`Critique`, `Important`, `Mineur`); `&nbsp;` keeps the label on one line.
- Under the table, one block that GitHub shows folded, a blank line after `</summary>` so its markdown renders:

  ```
  <details><summary>Détails</summary>

  [n]. [its proof]
  Piste de correction : [the direction]
  Reproduire : [the action]

  </details>
  ```

  One paragraph per finding, a blank line between two. Per finding: its proof is its § Details line translated (`Where:` → `Où :`, `Result:` → `Résultat :`, `Class:` → `Classe :`, `Decision:` → `Décision :`, `missing` → `manquant`, `deviates:` → `s'écarte :`, `extra:` → `en plus :`, `unclear:` → `pas clair :`), without its `Reproduce:` part and without its `Capture:`, plus what the constat left out (timings, config, values, error text). `Piste de correction :` when it has one; a visual one gets its capture right under it, attached by the user by hand, its path never in the text. `Reproduire :` for a `bug`, `test` or `pre-existing`: the action only, no values and no error text.
