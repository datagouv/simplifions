# Onglets des fiches démarche et solution

The edit page of a démarche reads in four DSFR tabs, `Fiche` · `Intégrations (<n>)` · `Recommandations (<n>)` · `Historique`; a solution's in `Fiche` · `API fournies (<n>)` · `API intégrées (<n>)` · `Solutions qui l’intègrent (<n>)` · `Recommandée dans (<n>)` · `Historique`. One form wraps the `Fiche`, the démarche's `Intégrations` and `Historique` tabs, so switching tabs loses nothing and `Enregistrer`, the draft and the leave warning work as before; the démarche's `Recommandations` and the solution's three integration tabs are line tables where each line saves on its own ([admin-recommandations-en-ligne.md](admin-recommandations-en-ligne.md), [admin-integrations-en-ligne.md](admin-integrations-en-ligne.md)), ignored by the column's `Enregistrer` and the leave warning; the `État et actions` column stays on the right. After a save the page reopens on the tab you were on (`?onglet=`); a refused save opens the tab of the first error (`Fiche` for a field, `Intégrations` for an out-of-rule intégration on a démarche). New démarche and solution pages have no tabs.

## Sub-features

- `onglets-demarche` four tabs `Fiche` · `Intégrations (<n>)` · `Recommandations (<n>)` · `Historique`, arrow keys move between them.
- `onglets-solution` a solution's tabs `Fiche` · `API fournies (<n>)` · `API intégrées (<n>)` · `Solutions qui l’intègrent (<n>)` · `Recommandée dans (<n>)` · `Historique` (spec only; `?onglet=api-fournies` opens the first).
- `onglets-enregistrer` one form across tabs: `Enregistrer` keeps changes from every tab and reopens the tab you were on (`?onglet=`).
- `onglets-erreur` a refused save opens the tab of the first error (`Fiche`; `Intégrations` for an out-of-rule intégration: spec only).
- `onglets-etroit` `?onglet=recommandations` opens that tab, no horizontal scroll at 375 px.
- `onglets-nouvelle` a new démarche or solution page has no tabs (spec only).

## How to get to it (user POV)

- `Démarches` → a démarche; `Solutions` → a solution. Admin only.

## Driving it with Capybara

Drive: `features/admin-onglets.rb` (SKILL.md § Drive).

Mutation on a throwaway démarche only (`Vérif verify-map <browser>`, deleted at the end).

- **Démarche 1.** Four tabs `Fiche`, `Intégrations`, `Recommandations`, `Historique`; page height read per tab; arrow right from `Fiche` selects `Intégrations` and the hidden `onglet` field follows.
- **Save from Intégrations.** Throwaway démarche recommending the most integrated API: check one intégration in `Intégrations`, that tab's `Enregistrer` → URL `?onglet=integrations`, `Intégrations (1)` selected, database has the intégration and the name unchanged.
- **Error opens Fiche.** From `Historique`, `Modifier l’en-tête`, empty `Nom`, `Enregistrer` → the modal open again with `doit être rempli` under `Nom`, `Fiche` selected; `Annuler`.
- **375 px.** `?onglet=recommandations` opens that tab, no horizontal scroll.
- **Proof.** `tmp/verify/admin-onglets/`.
