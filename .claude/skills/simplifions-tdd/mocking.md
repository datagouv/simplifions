# When to Mock

Mock at **system boundaries** only:

- External APIs (Grist, data.gouv): `stub_request` from webmock, fixtures in `spec/fixtures/`, shared stubs in `spec/support/` (`stub_grist_tables`)
- Databases (sometimes - prefer the test DB: create the records the test needs)
- Time: `Timecop`, or `travel_to`
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators (an interactor called by an organizer, a model method called by a controller)
- Anything you control

## Stubbing at the boundary

Stub the HTTP request, not the class that makes it: the code under test runs for real down to the network.

```ruby
# GOOD: the request is stubbed, the model runs its real code
it 'garde les valeurs précédentes quand data.gouv ne répond pas' do
  api.update!(datagouv_titre: 'Ancien titre')
  stub_request(:get, dataservice_url).to_timeout

  expect(api.rafraichir_datagouv!).to match(/Timeout/)
  expect(api.reload.datagouv_titre).to eq('Ancien titre')
end

# BAD: a client class written to be mocked, so the parsing and the error handling are never run
it 'garde les valeurs précédentes quand data.gouv ne répond pas' do
  allow(DatagouvClient).to receive(:fetch).and_raise(Timeout::Error)
  ...
end
```

- One stub per external call the test exercises, each returning one specific shape: no conditional logic in test setup.
- A stub used by several spec files goes in `spec/support/`, as `GristStubs` does.
- Never add an injected client or a wrapper class only to make the code mockable: webmock already stubs at the boundary, and a layer for one use is what `CLAUDE.md` § Où mettre le code forbids.
