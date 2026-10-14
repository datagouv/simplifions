# Design review with the user

Read at `/simplifions-review design <PR>`. A review done with the user, not for them: the agent brings facts and a second opinion, the user decides, and a page records the target design and each decision with its justification. Where responsibilities live is the point; line-level findings go to Notes. Modelled on a teammate's `manual-review-pr` skill (skelz0r/dotfiles).

Never post on the PR (comment, review, suggestion, label) unless the user asks for it later.

## 1. Own pass first

- Gather the diff and the commits as in `SKILL.md` step 1, and pin the head sha: every excerpt and link comes from it.
- The user's first remarks, if given, are the agenda: each one gets a verdict. Earlier notes of theirs on this PR are read only after the own pass: a second opinion primed by the first is worth half as much.
- Run Pass 3 ([`design-grid.md`](design-grid.md)) on the diff and on what it plugs into, and measure the shape against what is being built ([`../simplifions-plan/one-rule.md`](../simplifions-plan/one-rule.md)). The Codex second opinion runs as in `SKILL.md` step 4 when the PR is large or touches a costly area (money, access, personal data, proofs and attestations, public contracts).
- Check every claim against the code, the user's remarks included. When a remark rests on a wrong fact, say so, then answer the concern behind it.

## 2. Converse

- First message: the user's points one by one (agree or not, the fact, the alternative), then the own findings ranked, short, in the user's language. Links and `file:line`, no code dump.
- Then one topic per round, at the user's pace. Asked to explore: two or three approaches with honest costs, one recommended, the chosen one expanded as a sketch in the repository's idioms.
- If the user's direction has a cost or a hole, say it once, then follow their decision.
- Keep a ledger in `.notes/<branch>/design-review.md`, the page's source: **axes** (in the PR / target / why / consequences), **decisions** (the decision and the user's justification, in their words), **open questions**, **minor notes** (kept even when waved off).

Offer the page when the axes have converged; build it when asked.

## 3. The page

An Artifact: load `artifact-design` first. In the user's language, titled `<project> PR <n> — revue de conception` or its equivalent. Tabs, in this order:

1. **Overview**: a one-sentence verdict, what the PR does today, the axes table (in the PR / target / detail link), the proposed refactor order, what is kept as is.
2. **Final target**: the whole target at once: who does what (table), the request flow as an ASCII diagram, a sketch of each piece, what the next feature of the same kind has to write, what disappears from the PR.
3. **Solutions**: one sub-tab per axis: today (real excerpt, link pinned on the head sha), the problem, the decision with the user's justification, the target sketch, the consequences.
4. **Product decisions**: one block per decision with its justification; open questions last.
5. **Notes**: minor findings, for the record.

Rules:

- Real excerpts come from the pinned head sha; sketches say they are sketches and stay coherent from one tab to the other.
- The user's justifications are quoted as decisions, never turned into the agent's arguments.
- Look at every tab at desktop and phone width before giving the link. Do not link it from the PR unless asked.
