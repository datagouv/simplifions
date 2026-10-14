# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts. A page is tested by a request spec (`spec/requests/`).

```ruby
# GOOD: Tests observable behavior
it 'un visiteur voit les solutions recommandées sur la page de la démarche' do
  demarche = Demarche.create!(nom: 'Inscription à la cantine', slug: 'cantine', visible: true)
  # ... a visible recommended solution named 'Portail famille'

  get demarche_path(demarche.slug)

  expect(response).to have_http_status(:ok)
  expect(response.body).to include('Portail famille')
end
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only (a route, a public model method, an interactor's `call`)
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```ruby
# BAD: Tests implementation details
it 'appelle Grist::FetchTables' do
  expect(Grist::FetchTables).to receive(:call)
  Grist::Import.call
end
```

Red flags:

- Mocking internal collaborators
- Testing private methods (`send(:...)`)
- Asserting on call counts/order
- Asserting on ActiveRecord associations rather than on what they make visible (`CLAUDE.md` § Tests et style)
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```ruby
# BAD: Bypasses interface to verify
it 'enregistre la démarche' do
  sign_in admin
  post admin_demarches_path, params: { demarche: { nom: 'Cantine' } }
  expect(ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM demarches")).to eq(1)
end

# GOOD: Verifies through interface
it 'la démarche créée apparaît dans la liste de l’admin' do
  sign_in admin
  post admin_demarches_path, params: { demarche: { nom: 'Cantine' } }
  get admin_demarches_path
  expect(response.body).to include('Cantine')
end
```

**Tautological tests**: Expected value restates the implementation, so the test passes by construction.

```ruby
# BAD: Expected value is recomputed the way the code computes it
it 'compte les démarches visibles' do
  expect(Demarche.visibles.count).to eq(Demarche.where(visible: true).count)
end

# GOOD: Expected value is an independent, known literal
it 'compte les démarches visibles' do
  2.times { |i| Demarche.create!(nom: "D#{i}", slug: "d-#{i}", visible: true) }
  Demarche.create!(nom: 'Brouillon', slug: 'brouillon')
  expect(Demarche.visibles.count).to eq(2)
end
```
