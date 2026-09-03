require 'rails_helper'

load Rails.root.join('script/recette_parite.rb')

RSpec.describe RecetteParite do
  let(:ancien) do
    <<~HTML
      <html><body><header>Menu</header><main>
        <h1>Babily</h1><p>Solution   privée</p>
        <ul><li>Crèches</li><li>Familles</li></ul>
        <div class="api-or-dataset-card"><div class="api-or-dataset-header"><p class="fr-badge">API ouverte</p>
          <div class="logo"><img src="dinum.png"></div><h3><a href="/d">API Quotient familial</a></h3>
          <span class="org-name">DINUM</span></div></div>
        <p>Contenu rédigé par :<br><a href="/o">DINUM</a> le <time>2 septembre</time>.</p>
        <div id="tab-content-discussions"><h2>Discussions</h2><p>Connectez-vous pour démarrer une discussion</p></div>
      </main><footer>Pied</footer></body></html>
    HTML
  end

  let(:nouveau) do
    <<~HTML
      <html><body><main>
        <h1>Babily</h1>
        <p class="fr-text--lead">Solution privée</p>
        <ul><li>Crèches</li><li>Parents</li></ul>
        <div class="dataservice-card"><p class="fr-badge">À définir</p><img src="https://placehold.co/40x40">
          <h4><a href="/d">API Quotient familial</a></h4><p class="dataservice-card__org">DINUM</p></div>
        <p>Contenu rédigé par :<br>
          <a href="/o">DINUM</a>
          le <time>2 septembre</time>.</p>
        <table><tr hidden><td>Aucun endpoint ne correspond à votre recherche.</td></tr></table>
      </main></body></html>
    HTML
  end

  it 'extrait le texte de main par blocs et liens, sans éléments masqués, badge, logo, organisation ni discussions' do
    attendu = ['Babily', 'Solution privée', 'Crèches', 'Familles', 'API Quotient familial',
               'Contenu rédigé par :', 'DINUM', 'le 2 septembre.']
    expect(described_class.texte(ancien)).to eq attendu
    expect(described_class.texte(nouveau)).to eq(attendu.map { |ligne| ligne.sub('Familles', 'Parents') })
  end

  it 'compare deux textes et ne garde que les lignes qui diffèrent' do
    expect(described_class.comparer(%w[a b c], %w[a b c])).to eq []
    expect(described_class.comparer(%w[a b c], %w[a x c])).to eq ['- b', '+ x']
  end

  it 'donne à chaque page l’ancienne et la nouvelle URL, l’ancienne via le chemin redirigé' do
    expect(described_class.urls('Cas_d_usages:1', 'cantine', 'https://staging.example'))
      .to eq ['https://simplifions.data.gouv.fr/cas-d-usages/cantine', 'https://staging.example/cas-d-usages/cantine',
              'https://staging.example/demarches/cantine']
    expect(described_class.urls('Solutions:2', 'babily', 'https://staging.example'))
      .to eq ['https://simplifions.data.gouv.fr/solutions/babily', 'https://staging.example/solutions/babily',
              'https://staging.example/solutions/babily']
  end

  it 'rend un rapport Markdown lisible : tableau des statuts puis diffs' do
    resultats = [
      { slug: 'cantine', nouvelle: 'https://s/demarches/cantine', diff: [], erreur: nil },
      { slug: 'babily', nouvelle: 'https://s/solutions/babily', diff: ['- Familles', '+ Parents'], erreur: nil },
      { slug: 'inoe', nouvelle: 'https://s/solutions/inoe', diff: [], erreur: 'HTTP 404' }
    ]

    rapport = described_class.rapport(resultats, 'https://s')

    expect(rapport).to include('| [cantine](https://s/demarches/cantine) | ✅ identique |')
    expect(rapport).to include('| [babily](https://s/solutions/babily) | ⚠️ 2 lignes différentes |')
    expect(rapport).to include('| [inoe](https://s/solutions/inoe) | ❌ HTTP 404 |')
    expect(rapport).to include("### babily\n\n```diff\n- Familles\n+ Parents\n```")
    expect(rapport).not_to include('### cantine')
  end
end
