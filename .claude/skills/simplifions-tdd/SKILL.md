---
name: simplifions-tdd
description: Test-driven development in Simplifions. Use when building features or fixing bugs test-first, at each red-green step of /simplifions-ship, or when the user mentions "red-green-refactor" or integration tests.
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle — consult them before and during the loop, not after.

Test names and interface vocabulary follow the domain words of the code and the issue (démarche, solution, cas d'usage…). `CLAUDE.md` § Tests et style says where specs go and how to run them.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification — "un visiteur voit les solutions d'une démarche publiée" tells you exactly what capability exists — and survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and check them against the plan's steps, which name them. No test is written at a seam the plan does not name. A seam is a technical choice: it is never asked of the user ([`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides)); a seam the plan missed goes in the PR body for Thomas. You can't test everything — agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** — the assertion recomputes the expected value the way the code does (`expect(total(a, b)).to eq(a + b)`, an expected HTML fragment built the way the view builds it, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth — a known-good literal, a worked example, the spec.
- **Horizontal slicing** — writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring follows `simplifions-ship/red-green-commit.md`**: step 5 of each cycle for the step's own code, the plan's Simplify step for the whole change, then `/simplifions-review`.
