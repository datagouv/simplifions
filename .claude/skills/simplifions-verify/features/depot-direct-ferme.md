# Dépôt direct de fichiers fermé

Active Storage's direct upload address answers 404 to everyone, visitor or signed-in admin, and creates no file in the database. Admin images still go through the solution form (`admin-brouillon.md`, `admin-image-refusee.md`), and published images stay readable by anyone.

## Sub-features

- `depot-direct-visiteur` a visitor's POST with a valid CSRF token answers 404, no blob created.
- `depot-direct-admin` the same POST from a signed-in admin answers 404, no blob created.

## How to get to it (user POV)

- No link: `POST /rails/active_storage/direct_uploads` with a JSON `blob` (filename, byte_size, checksum, content_type) and the page's `X-CSRF-Token`, as a script on any page would send it.

## Driving it with Capybara

Preconditions:

- Launch done and doctor green (SKILL.md § Launch, § Doctor).
- The dev-only admin exists (`Verify.ensure_admin`, SKILL.md § Enter).

`drive.rb depot-direct`.

- **Visitor.** On `/`, `fetch` the POST from the page with its CSRF token → status 404, `ActiveStorage::Blob.count` unchanged.
- **Admin.** `Verify.login(page)`, same `fetch` → 404, count unchanged; `Verify.logout(page)`.
- **Proof.** `tmp/verify/depot-direct-ferme/`: one screenshot and one `read-back.txt` line per step, `statut=404 fichiers_crees=0`.

## Gotchas

- The blob count is read inside `ActiveRecord::Base.uncached`: the POST runs in the server thread, the read-back in the runner.
- On a branch without the closing route the POST answers 200 and creates a blob: delete it with `ActiveStorage::Blob.unattached.where(filename: 'piege.png').destroy_all`.
