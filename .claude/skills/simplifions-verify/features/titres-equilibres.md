# Titres sur deux lignes équilibrés

A catalogue card title or a page's main title (H1) that wraps spreads its words over lines of close length instead of leaving one or two words alone on the last line; size and visible weight unchanged.

## Sub-features

- `titres-cartes` — card titles of `/demarches` and `/solutions`.
- `titres-h1` — the H1 of a cas d'usage, a solution and an article page (and every other public page).

## How to get to it (user POV)

- Header menu `Cas d'usages` or `Solutions`, then any card; `/articles`, then any article.
- Anyone, no login. Shows only where a title wraps: phone width for most H1s, desktop for the longest card titles.

## Driving it with Capybara

Drive: `features/titres-equilibres.rb` (SKILL.md § Drive).

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- Catalogue imported: the drive picks the longest démarche title, solution name and article H1.

- **Catalogue cards.** At 390 then 1280 px, `visit '/demarches'` and `'/solutions'`; the longest two-line card title is scrolled into view and captured, its lines in the read-back.
- **Page titles.** Same two widths on the démarche, solution and article with the longest title; H1 captured, its lines in the read-back.
- **Proof.** Every title seen computes `text-wrap-style: balance`.

## Gotchas

- Firefox headless does not shrink below about 500 px: its « 390 » captures are 500 px wide (the read-back prints the real width).
- The read-back splits lines by word position; a title on one line at that width prints one string.
- Safari before 17.5 ignores `text-wrap: balance` and keeps the old breaks; not driven here.
