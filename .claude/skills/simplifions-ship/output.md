# Output templates

`<compare link>` is `https://github.com/datagouv/simplifions/compare/<branch>?expand=1`, with the full git branch name: the user opens it in a browser and pastes the title and body to open the PR.

### When resuming:
```
Resuming SIM-124 (started YYYY-MM-DD), phase implement, step 3/5.
```

### When shipped:
```
Shipped SIM-124 — review clean after 2 rounds — proof: tmp/verify/<feature>/
Open the PR: <compare link>
Title: <title>
Body:
<body>
(a large PR) In Linear, attach the file .notes/<branch_name>/review-guide.md to https://linear.app/pole-api/issue/SIM-124
```

### When the review cap is hit:
```
SIM-124 — 3 review rounds done, findings still open:
  - [finding]
Suspect: design | scope — [why]
Open the PR for Thomas: <compare link>
Title: <title>
Body:
<body, the open findings listed for Thomas>
```

### When skipped:
```
SIM-124 not shipped: the plan has open questions. Run /simplifions-plan SIM-124 to resolve them.
(or) SIM-124 not shipped: the plan's `Flag:` waits for Thomas's technical go-ahead.
```

### When blocked or on error:
```
SIM-124 not shipped: [what stopped the drive, the design that did not hold, or the error]
(a design that did not hold) Comment for Thomas, to post on https://linear.app/pole-api/issue/SIM-124:
<comment>
Session saved. Run /simplifions-ship SIM-124 to retry; after Thomas answers on a design, /simplifions-plan SIM-124 first.
```
