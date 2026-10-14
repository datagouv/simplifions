# Formulaire solution adapté à sa catégorie

A solution's admin form shows only the fields of its catégorie: for `API` or `Jeu de données` the fiche fields (Slug, Site internet, URL de demande d’accès, Image principale, Légende de l’image, Description courte, Cette solution permet / ne permet pas) are hidden (`fr-hidden`) and disabled, on render and as soon as the `Catégorie de solution` select changes; a fiche field filled on screen or on render (and the image group while an image is shown) stays visible and enabled, so it can be emptied in the same save. The current image is shown (alt = légende) with a `Retirer l’image` box and the hint `Formats acceptés : png, jpg, webp`. A private solution carries a `Privée` badge under its H1 and in the `Privée` column of the list (`Oui`/`Non`, like `Visible`).

## How to get to it (user POV)

- `/admin/solutions/<id>/edit` and `/admin/solutions`. Admin only.

## Driving it with Capybara

`drive.rb formulaire-solution`, on a solution it creates (`Vérif verify-map <browser>`, Brique technique, image + légende, no organisation) and deletes.

- **Privée.** Badge under the H1; list searched by name shows `Oui` in `Privée`.
- **Image.** Preview alt = légende, hint lists the formats.
- **Catégorie.** Select `API` → empty Slug and Description courte hidden and disabled, the filled légende and the image group (`Retirer l’image`) stay visible and enabled; `Annuler` asks « Quitter sans enregistrer » (#81 still sees the change); back to `Brique technique` → all visible.
- **One save.** Empty the légende, tick `Retirer l’image`, select `API` (the emptied légende stays visible: its rendered value was filled), `Enregistrer` → database: catégorie api, no légende, no image.
- **Proof.** `tmp/verify/admin-formulaire-solution/`, including `etroit-320`.

## Gotchas

- Read-backs after a mutation go through `ActiveRecord::Base.uncached`.
- A failed run leaves the `Vérif verify-map` solution: the drive deletes it in `ensure`.
