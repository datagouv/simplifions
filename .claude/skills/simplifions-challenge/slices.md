# Split granularity

Read at step 6 of the challenge framework, only when recommending a split, and whenever work is split into issues or PRs.

Splitting an oversized issue is correct — but the right grain is **the smallest change that still delivers coherent, reviewable functionality**, not the smallest change possible. A PR must let the reviewer see the global purpose; over-atomic splits destroy that.

- Each resulting issue = a **vertical slice** (thin end-to-end functionality the user or system can observe), not a **horizontal layer** (a "model" PR, a "controller" PR, a "tests" PR — never split this way).
- **One-sentence test**: each sub-issue must be describable in one sentence of *functional* value ("parents can see their invoice"). If you can only describe it by its implementation mechanics ("add the `Invoice` model"), it's too atomic — merge it back.
- A PR that brings no observable behavior on its own is a sliver, not a slice. Prefer fewer, story-telling PRs over many mechanical ones.
- Sequencing dependencies (slice B builds on slice A) is fine and expected — that's phasing, not atomizing.
- A PR should tell one story.
