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

    expect(response.body).to include("[objet, porte(element, 'contexte')].filter(Boolean).join(' — ')")
    expect(response.body).to include("_paq.push(['trackEvent', porte(element, 'zone') || 'Autre', element.dataset.matomoAction, nom])")
  end

  it 'n’envoie un bouton, un onglet ou un détail qu’à son ouverture, sauf s’il nomme aussi sa fermeture' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("['aria-expanded', 'aria-pressed', 'aria-selected']")
    expect(response.body).to include("(element.matches('summary') && element.parentElement.open)")
    expect(response.body).to include("closest('button[data-matomo-action], summary[data-matomo-action]')")
    expect(response.body).to include("element.getAttribute('aria-disabled') === 'true') return;")
    expect(response.body).to include('envoyerEvenement(bouton, null, bouton.dataset.matomoFermeture)')
  end

  it 'envoie le libellé choisi dans une liste ou parmi des boutons radio' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("addEventListener('change'")
    expect(response.body).to include("closest('select[data-matomo-action], fieldset[data-matomo-action]')")
    expect(response.body).to include('envoyerEvenement(champ, choix.textContent.trim())')
    expect(response.body).to include("[porte(element, 'nom'), choix].filter(Boolean).join(' : ')")
  end

  it 'mesure les liens e-mail sans les compter comme liens sortants' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include('/^(https?|mailto):$/.test(lien.protocol)')
    expect(response.body).to include("if (lien.protocol === 'mailto:') return;")
  end

  it 'mesure les liens d’un texte sans action propre, sous leur libellé' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("else if (porte(lien, 'liens')) envoyerEvenement(lien, libelleDuLien(lien), porte(lien, 'liens'))")
  end

  it 'nomme les pages 404 avec leur chemin et la page d’origine' do
    allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

    get root_path

    expect(response.body).to include("'404/URL = ' + encodeURIComponent(location.pathname)")
    expect(response.body).to include("'/From = ' + encodeURIComponent(urlPrecedente)")
  end

  describe 'zones communes à toutes les pages' do
    def zone_matomo(element) = element.find(:xpath, 'ancestor-or-self::*[@data-matomo-zone][1]')['data-matomo-zone']
    def liens_matomo(element) = element.find(:xpath, 'ancestor-or-self::*[@data-matomo-liens][1]')['data-matomo-liens']

    it 'mesure l’en-tête, le pied de page et tous les liens d’une page de contenu' do
      get about_path
      page = Capybara.string(response.body)

      menu = page.find('#button-menu')
      expect([zone_matomo(menu), menu['data-matomo-action']]).to eq(['Navigation › En-tête', 'Ouvrir le menu'])
      expect(liens_matomo(page.find('.fr-nav__link', text: 'Articles'))).to eq('Aller vers une rubrique')
      expect(page.find_link('Se connecter')['data-matomo-action']).to eq('Se connecter')
      pied = page.find('footer').find_link('Plan du site')
      expect([zone_matomo(pied), liens_matomo(pied)]).to eq(['Navigation › Pied de page', 'Aller vers une page'])
      contenu = page.find('main')
      expect([contenu['data-matomo-zone'], contenu['data-matomo-liens']]).to eq(['Page › À propos', 'Suivre un lien'])
      fil = page.find('.fr-breadcrumb')
      expect([fil['data-matomo-zone'], fil['data-matomo-liens']]).to eq(["Navigation › Fil d'Ariane", 'Remonter vers'])
      expect(fil.find('button')['data-matomo-action']).to eq("Déplier le fil d'Ariane")
    end

    it 'mesure le sommaire et la proposition de modification d’une fiche' do
      Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)

      get demarche_path('cantine')
      page = Capybara.string(response.body)

      sommaire = page.find('nav.fr-summary')
      expect([sommaire['data-matomo-zone'], sommaire['data-matomo-liens']]).to eq(['Navigation › Sommaire', 'Aller à une section'])
      expect(sommaire.find_link('Direction interministérielle du numérique')['data-matomo-action']).to eq('Ouvrir la page de la DINUM')
      bloc = page.find('section[aria-labelledby="titre-proposer-modification"]')
      expect(bloc['data-matomo-zone']).to eq('Proposer une modification')
      expect(bloc.find_link('proposer vos modifications de cette démarche')['data-matomo-action']).to eq('Proposer une modification')
      flottant = page.find('a.bouton-proposer-modification')
      expect([flottant['data-matomo-zone'], flottant['data-matomo-action']])
        .to eq(['Proposer une modification', 'Proposer une modification (bouton flottant)'])
    end

    it 'nomme un lien sans texte par son titre ou par le texte de son image' do
      allow(ENV).to receive(:[]).with('MATOMO_SITE_ID').and_return('311')

      get root_path

      expect(response.body).to include("lien.textContent.replace(/\\s+/g, ' ').trim() || lien.title || (image && image.alt)")
    end
  end
end
