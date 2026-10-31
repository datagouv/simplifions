require 'rails_helper'

RSpec.describe 'Matomo' do
  before { allow(ENV).to receive(:[]).and_call_original }

  it 'ne charge rien sans MATOMO_SITE_ID' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return(nil)

    get root_path

    expect(response.body).not_to include('stats.data.gouv.fr')
  end

  it 'charge le tag standard avec le site id fourni' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include('https://stats.data.gouv.fr/')
    expect(response.body).to include("_paq.push(['setTrackerUrl', u + 'matomo.php'])")
    expect(response.body).to include("_paq.push(['setSiteId', '311'])")
  end

  it "n'envoie que le chemin de la page, sans ses paramètres" do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("_paq.push(['setCustomUrl', location.origin + location.pathname])")
  end

  it 'mesure chaque page affichée par Turbo, pas seulement le premier chargement' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    script = response.parsed_body.css('head script').map(&:text).find { |texte| texte.include?('matomo.js') }
    expect(script).to include("addEventListener('turbo:load'")
  end

  it 'donne au tag le mot-clé, le catalogue et le nombre de résultats de la recherche' do
    Demarche.create!(nom: 'Tarification EAJE', slug: 'eaje', visible: true)

    get demarches_path(q: 'eaje')

    formulaire = response.parsed_body.at_css('form.catalogue')
    expect(formulaire['data-matomo-recherche']).to eq('eaje')
    expect(formulaire['data-matomo-catalogue']).to eq("Cas d'usages")
    expect(formulaire['data-matomo-resultats']).to eq('1')
  end

  it 'donne zéro résultat dans le catalogue des solutions quand rien ne correspond' do
    get solutions_path(q: 'zzzz')

    formulaire = response.parsed_body.at_css('form.catalogue')
    expect(formulaire['data-matomo-catalogue']).to eq('Solutions')
    expect(formulaire['data-matomo-resultats']).to eq('0')
  end

  it 'range chaque événement dans la zone de la page où il a lieu, avec le cas d’usage ou la fiche concernés' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("[porte(element, 'nom'), porte(element, 'contexte')].filter(Boolean).join(' — ')")
    expect(response.body).to include("_paq.push(['trackEvent', porte(element, 'zone') || 'Autre', element.dataset.matomoAction, nom])")
    expect(response.body).to include("bouton.getAttribute('aria-expanded') !== 'true' && bouton.getAttribute('aria-pressed') !== 'true'")
  end

  it 'nomme les pages 404 avec leur chemin et la page d’origine' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("'404/URL = ' + encodeURIComponent(location.pathname)")
    expect(response.body).to include("'/From = ' + encodeURIComponent(urlPrecedente)")
  end
end
