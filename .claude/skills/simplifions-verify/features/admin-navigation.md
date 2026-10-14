# Naviguer dans l'administration depuis l'en-tête

Under `/admin`, the header's navigation bar (`Menu de l’administration`) lists the seven rubriques — Démarches, Solutions, Recommandations, Intégrations, Organisations, Fournisseurs de services, Vocabulaires — instead of the public one (`Menu principal`: Accueil, Cas d'usages, Articles, À propos). The rubrique of the page is marked: `aria-current="page"` on its list, `aria-current="true"` on its sub-pages (new, edit, read page, a fiche's history), as the DSFR asks for a parent section. Public pages and the login page keep the public bar, even for a logged-in admin.

## How to get to it (user POV)

- Any `/admin/*` page once logged in; on a narrow screen, header button `Menu`.

## Driving it with Capybara

`drive.rb navigation`, read-only.

- **Tableau de bord.** `/admin`: the admin bar lists the seven rubriques in order, none current; no `Menu principal`.
- **Rubrique.** Click `Solutions` in the bar: `/admin/solutions`, `Solutions` is `page`. Open a solution's edit page, then its history: `Solutions` is `true`.
- **Mobile.** At 375 px, `Menu` opens the modal with the seven rubriques; `Vocabulaires` leads to `/admin/vocabulaires`, current; no horizontal scroll.
- **Site public.** `/` as a logged-in admin: `Menu principal` only.
- **Proof.** `tmp/verify/admin-navigation/`.
