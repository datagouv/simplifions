# Pages de l'admin sur toute la largeur

After login, every `/admin` page, its header and its footer take the whole window from 1248 px up (78em, where the public site stops growing), with a 1.5rem margin on each side; below 1248 px they look as before. The previewed page (`Prévisualiser`) keeps the public width, so it shows as a visitor will see it. The public site and the login page keep the public width.

## Sub-features

- `largeur-admin` admin content, header and footer as wide as the window at 1440 px.
- `largeur-1024` at 1024 px, the same widths as the public site (unchanged).
- `largeur-previsualisation` the previewed page keeps the public width; the admin header above it widens.
- `largeur-publique` public pages and `/admin/connexion` unchanged.
- `panneau-collant` the side panel `État et actions` of a fiche still follows the scroll.

## How to get to it (user POV)

- Log in, then any page of the admin menu (`À reprendre`, `Démarches`, `Solutions`, `Référentiels`), a fiche from a list, `Prévisualiser` from a fiche.
- The public home `/` for comparison.

## Driving it with Capybara

Drive: `features/admin-pleine-largeur.rb` (SKILL.md § Drive).

Preconditions: logged in; a solution in the catalogue (the one with the most API fournies). Nothing is written.

- **Public width.** `/` at 1440 px: header, content and footer 1248 px wide.
- **Admin width.** `/admin`, `/admin/organisations` and the solution's fiche at 1440 px: header, content and footer as wide as the window.
- **Admin at 1024 px.** The same pages at 1024 px: as wide as `/` at 1024 px.
- **Preview.** `/admin/solutions/<id>/previsualisation` at 1440 px: the previewed content 1248 px wide.
- **Sticky panel.** The solution's fiche at 1440 px, scrolled 900 px down: the top of `État et actions` 16 px from the top of the window.
- **Proof.** Screenshots and `read-back.txt` (the widths read) in `tmp/verify/admin-pleine-largeur/`.

## Gotchas

- Widths are read from the elements' bounding boxes; the window width is `document.documentElement.clientWidth` (the scrollbar left out, so 1425 or 1428 px for a 1440 px window).
- The demarche preview may fail on a démarche with solutions intégratrices until that bug is fixed; the drive previews a solution.
