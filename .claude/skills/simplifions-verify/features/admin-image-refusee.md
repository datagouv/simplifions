# Image de solution refusée hors png, jpg, webp

The server refuses a solution image whose content is not png, jpeg or webp, whatever its file name: error `doit être une image png, jpg ou webp` under `Image principale` and in the summary, HTTP 422, the other typed fields kept in the form. A hidden solution keeps no file; a published one writes no draft and keeps no blob. A file with no signature (plain text) keeps the type of its extension. The Grist import notes `Solutions:N — image M : type <x> refusé` instead (request and interactor specs only).

## Sub-features

- `image-refusee` a content other than png, jpg, webp is refused under `Image principale`, other fields kept; no file, no draft, no blob.
- `image-refusee-acceptee` a real png goes into the draft of a published solution.
- `image-refusee-texte` a file with no signature keeps the type of its extension (not driven).
- `image-refusee-import` the Grist import notes `Solutions:N — image M : type <x> refusé` (spec only).

## How to get to it (user POV)

- `/admin` → `Solutions` → a row → `Image principale` → `Enregistrer`. Admin only.

## Driving it with Capybara

Drive: `features/admin-image-refusee.rb` (SKILL.md § Drive).

Writes `tmp/verify/pdf-nomme.png` (PDF bytes) and creates a hidden solution `Vérif verify-map <browser> masquée` and a published one `Vérif verify-map <browser>`; deletes both.

- **Refusal, hidden then published.** `Nom` `<nom> renommée`, attach the file, `Enregistrer`: the error in the upload group, `Nom` still `<nom> renommée`; base name unchanged, no image, no draft, blob count unchanged.
- **Accepted.** On the published one, attach `app/assets/images/articles/api-franceconnectees-donnees-personnelles.png`, `Enregistrer`: draft badge, draft holds the image.
- **Proof.** `tmp/verify/admin-image-refusee/`.
