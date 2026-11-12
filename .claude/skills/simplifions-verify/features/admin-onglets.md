# Onglets de la fiche solution

The edit page of a solution reads in DSFR tabs, `Fiche` · `API fournies (<n>)` · `API intégrées (<n>)` · `Solutions qui l’intègrent (<n>)` · `Recommandée dans (<n>)` · `Historique`. One form wraps the tabs, so switching tabs loses nothing and `Enregistrer`, the draft and the leave warning work as before; the three integration tabs save each line on its own ([admin-integrations-en-ligne.md](admin-integrations-en-ligne.md)), ignored by the column's `Enregistrer` and the leave warning; the `État et actions` column stays on the right. After a save the page reopens on the tab you were on (`?onglet=`); a refused save opens `Fiche`. A démarche has no tabs: one page of blocks ([admin-fiche-demarche.md](admin-fiche-demarche.md)). New démarche and solution pages have no tabs.

## Sub-features

- `onglets-demarche-aucun` a démarche's edit page has no tablist.
- `onglets-solution` the six tabs; arrow keys move between them and the hidden `onglet` field follows.
- `onglets-enregistrer` one form across tabs: `Enregistrer` keeps changes from every tab and reopens the tab you were on (`?onglet=`).
- `onglets-erreur` a refused save opens `Fiche`.
- `onglets-etroit` `?onglet=historique` opens that tab, no horizontal scroll at 375 px.
- `onglets-nouvelle` a new démarche or solution page has no tabs (spec only).

## How to get to it (user POV)

- `Solutions` → a solution; `Démarches` → a démarche. Admin only.

## Driving it with Capybara

Drive: `features/admin-onglets.rb` (SKILL.md § Drive).

Mutation on a throwaway hidden démarche and solution only (`Vérif verify-map <browser>`, deleted at the end). Preconditions: logged in.

- **Démarche without tabs.** The démarche's page has `Modifier le contexte` and no tablist.
- **Solution tabs.** Six tabs in order; arrow right from `Fiche` selects `API fournies` and the hidden `onglet` field follows.
- **Save from Historique.** Fill `Nom` in `Fiche`, open `Historique`, `Enregistrer` → URL `?onglet=historique`, `Historique` selected, base has the new name.
- **Error opens Fiche.** Empty `Nom`, open `Historique`, `Enregistrer` → `doit être rempli`, `Fiche` selected.
- **375 px.** `?onglet=historique` opens that tab, no horizontal scroll.
- **Proof.** `tmp/verify/admin-onglets/`.

## Gotchas

- In Firefox a solution save takes about 8 s, past Capybara's 5 s wait: the drive waits 15 s after `Enregistrer`.
