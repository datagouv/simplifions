# Onglets des fiches démarche et solution

The edit page of a démarche reads in four DSFR tabs, `Fiche` · `Intégrations (<n>)` · `Recommandations (<n>)` · `Historique`; a solution's in `Fiche` · `Intégrations (<n>)` · `Recommandée dans (<n>)` · `Historique`. One form wraps every tab, so switching tabs loses nothing and `Enregistrer`, the draft and the leave warning work as before; the `État et actions` column stays on the right. After a save the page reopens on the tab you were on (`?onglet=`); a refused save opens the tab of the first error (`Fiche` for a field, `Intégrations` for an out-of-rule intégration). New démarche and solution pages have no tabs.

## How to get to it (user POV)

- `Démarches` → a démarche; `Solutions` → a solution. Admin only.

## Driving it with Capybara

`drive.rb onglets`, mutation on a throwaway démarche only (`Vérif verify-map <browser>`, deleted at the end).

- **Démarche 1.** Four tabs; page height read per tab; arrow right from `Fiche` selects `Intégrations` and the hidden `onglet` field follows.
- **Save from Intégrations.** Throwaway démarche recommending the most integrated API: rename it in `Fiche`, check one intégration in `Intégrations`, `Enregistrer` → URL `?onglet=integrations`, `Intégrations (1)` selected, database has the new name and the intégration.
- **Error opens Fiche.** Empty `Nom` in `Fiche`, switch to `Historique`, `Enregistrer` → error summary, `Fiche` selected, `Nom` visible.
- **375 px.** `?onglet=recommandations` opens that tab, no horizontal scroll.
- **Proof.** `tmp/verify/admin-onglets/`.
