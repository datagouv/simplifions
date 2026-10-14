# Review guide for a large PR

Read at `/simplifions-ship` phase 4 and at `gh pr create` when the PR cannot be read commit by commit in one sitting: roughly more than ten commits, or generated files outweighing the hand-written change. Model: Loïc's guide for Apistration #395 (545 files, 46 000 lines, 2026-09), https://assets.delmai.re/apistration-pr-395/.

Write `.notes/<branch>/review-guide.md` in French, these sections in this order:

1. **Vue d'ensemble** — what changed in one sentence, then the deliverables per surface (pages, admin, import, data…).
2. **Exemple de bout en bout** — one concrete case followed through every stage the change touches, from declaration to what the visitor or the admin sees.
3. **Architecture** — the layers the change adds or moves, one paragraph each, and the notable refactorings.
4. **Gardes-fous** — the tests that keep the pieces from diverging, what they cover, what they do not.
5. **Commits & tests** — the commits in reading order, each with « ce qu'il faut lire » (the files and the idea, not the diff), and the commands to run locally. Split the essential hand-written lines from the skimmable generated ones, with the counts.

The guide is attached to the Linear issue as a file (`simplifions-work` § Linear, attach a file), and the PR body's third line says so. It never replaces the commits: it tells the reviewer which one to open next.
