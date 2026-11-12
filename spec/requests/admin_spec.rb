require 'rails_helper'

RSpec.describe 'Administration' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  describe 'GET /admin' do
    it 'renvoie vers la page de connexion sans admin connecté' do
      get admin_root_path
      expect(response).to redirect_to(new_admin_session_path)
      follow_redirect!
      expect(response.body).to include('Vous devez vous connecter pour accéder à cette page.')
    end

    it 'dit bonjour une fois connecté' do
      sign_in admin
      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('h1').text).to eq('Bonjour')
      expect(response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }).to eq(['Administration'])
    end

    it 'mène à chaque table du catalogue' do
      sign_in admin
      get admin_root_path
      %w[demarches solutions organisations types_acteurs vocabulaires].each do |chemin|
        expect(response.body).to include("href=\"/admin/#{chemin}\"")
      end
    end
  end

  describe 'catalogue sur la page d’accueil' do
    before { sign_in admin }

    def catalogue = response.parsed_body.css('section[aria-labelledby=catalogue] li').map { it.text.squish }

    it 'compte chaque table, les démarches et les solutions avec leurs publiées' do
      Demarche.create!(nom: 'Aides', slug: 'aides', visible: true)
      Demarche.create!(nom: 'Bourses')
      Solution.create!(nom: 'API QF', categorie: 'api', visible: true)
      Organisation.create!(nom: 'DINUM')

      get admin_root_path
      expect(catalogue).to eq(['Démarches 2 · 1 publiée', 'Solutions 1 · 1 publiée', 'Organisations 1',
                               'Fournisseurs de services 0', 'Vocabulaires 0'])
    end

    it 'mène chaque nombre à sa liste' do
      get admin_root_path
      expect(response.parsed_body.css('section[aria-labelledby=catalogue] a').pluck('href'))
        .to eq(%w[/admin/demarches /admin/solutions /admin/organisations /admin/types_acteurs /admin/vocabulaires])
    end
  end

  describe 'À reprendre sur la page d’accueil' do
    before { sign_in admin }

    def a_reprendre = response.parsed_body.at_css('section[aria-labelledby=a-reprendre]')
    def brouillons = a_reprendre.css('li').map { |brouillon| brouillon.css('p').map { it.text.squish } }

    it 'liste les démarches et les solutions en brouillon, la plus récente d’abord, avec ce qui a changé' do
      aides = Demarche.create!(nom: 'Aides', icone: '🛟', slug: 'aides', visible: true)
      aides.enregistrer('nom' => 'Aides', 'contexte' => 'Nouveau contexte', 'slug' => 'aides-sociales',
        'modifie_le' => Time.zone.local(2026, 11, 3, 10))
      annuaire = Solution.create!(nom: 'Annuaire', categorie: 'site_de_consultation', slug: 'annuaire', visible: true)
      annuaire.enregistrer({ 'nom' => 'Annuaire', 'description_courte' => 'Trouver une entreprise',
                             'modifie_le' => Time.zone.local(2026, 10, 28, 10) })
      Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)

      get admin_root_path
      expect(brouillons).to eq([
        ['Démarche · brouillon du 03/11/2026', '🛟 Aides', 'Contexte et adresse de la page modifiés'],
        ['Solution · brouillon du 28/10/2026', 'Annuaire (Portail de consultation)', 'Description courte modifiée']
      ])
      expect(a_reprendre.css('li a').pluck('href')).to eq(["/admin/demarches/#{aides.id}/edit", "/admin/solutions/#{annuaire.id}/edit"])
      expect(a_reprendre.at_css('h2').text.squish).to eq('À reprendre 2 brouillons')
    end

    it 'compte les recommandations en brouillon d’une démarche par sorte, datée par la plus récente' do
      bourses = Demarche.create!(nom: 'Bourses', slug: 'bourses', visible: true)
      bourses.enregistrer('nom' => 'Bourses', 'contexte' => 'Nouveau contexte', 'modifie_le' => Time.zone.local(2026, 11, 1, 9))
      ['API QF', 'API Bourses'].each do |nom|
        solution = Solution.create!(nom:, categorie: 'api', visible: true)
        bourses.recommandations.new(solution:, niveau: :niveau_2).enregistrer('modifie_le' => Time.zone.local(2026, 11, 2, 9))
      end
      utile = bourses.recommandations.create!(solution: Solution.create!(nom: 'API Revenus', categorie: 'api'), niveau: :niveau_1, visible: true)
      utile.enregistrer('description' => 'Revenus du foyer', 'modifie_le' => Time.zone.local(2026, 10, 30, 9))

      get admin_root_path
      expect(brouillons).to eq([['Démarche · brouillon du 02/11/2026', 'Bourses',
                                 'Contexte modifié, 2 solutions recommandées ajoutées, 1 donnée utile modifiée']])
    end

    it 'nomme les liaisons changées par leur table' do
      vocabulaire = Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      aides = Demarche.create!(nom: 'Aides', visible: true, slug: 'aides')
      aides.enregistrer('vocabulaire_ids' => [vocabulaire.id.to_s], 'modifie_le' => Time.zone.local(2026, 11, 3, 10))

      get admin_root_path
      expect(brouillons.first.last).to eq('Vocabulaires modifiés')
    end

    it 'accorde au féminin les champs féminins d’une solution' do
      dinum = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')
      api = Solution.create!(nom: 'API QF', categorie: 'api', visible: true)
      api.enregistrer({ 'organisation_ids' => [dinum.id.to_s], 'france_connectee' => '1', 'modifie_le' => Time.zone.local(2026, 11, 3, 10) })

      get admin_root_path
      expect(brouillons.first.last).to eq('API FranceConnectée et organisations modifiées')
    end

    it 'range une solution recommandée passée en donnée utile avec les données utiles' do
      bourses = Demarche.create!(nom: 'Bourses', slug: 'bourses', visible: true)
      recommandation = bourses.recommandations.new(solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_2)
      recommandation.enregistrer('modifie_le' => Time.zone.local(2026, 11, 2, 9))
      recommandation.enregistrer('niveau' => 'niveau_1', 'modifie_le' => Time.zone.local(2026, 11, 2, 10))

      get admin_root_path
      expect(brouillons.first.last).to eq('1 donnée utile ajoutée')
    end

    it 'dit qu’aucun brouillon n’attend' do
      Demarche.create!(nom: 'Cantine')
      get admin_root_path
      expect(a_reprendre.text.squish).to eq('À reprendre Aucun brouillon en cours.')
    end
  end

  describe 'dernières modifications sur la page d’accueil' do
    include ActiveSupport::Testing::TimeHelpers

    before { sign_in admin }

    def modifications = response.parsed_body.css('section[aria-labelledby=dernieres-modifications] tbody tr').map { |ligne| ligne.css('td').map { it.text.squish } }
    def liens = response.parsed_body.css('section[aria-labelledby=dernieres-modifications] tbody a').pluck('href')

    it 'donne la dernière modification de chaque fiche, la plus récente d’abord, sans lien vers une fiche supprimée' do
      travel_to(Time.zone.local(2026, 11, 1, 9)) { Organisation.create!(nom: 'AIFE').destroy! }
      cantine = travel_to(Time.zone.local(2026, 11, 2, 9)) { Demarche.create!(nom: 'Cantine') }
      travel_to(Time.zone.local(2026, 11, 3, 14, 12)) { cantine.update!(nom: 'Cantine scolaire') }
      communes = travel_to(Time.zone.local(2026, 11, 3, 15)) { TypeActeur.create!(nom: 'Communes') }

      get admin_root_path
      expect(modifications).to eq([
        ['Fournisseur de services', 'Communes', 'Ajouté', '03/11/2026 à 15:00'],
        ['Démarche', 'Cantine scolaire', 'Modifiée', '03/11/2026 à 14:12'],
        ['Organisation', 'AIFE', 'Supprimée', '01/11/2026 à 09:00']
      ])
      expect(liens).to eq(["/admin/types_acteurs/#{communes.id}", "/admin/demarches/#{cantine.id}/edit"])
    end

    it 'nomme une recommandation supprimée avec sa démarche supprimée' do
      api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
      Demarche.create!(nom: 'Bourses').tap { it.recommandations.create!(solution: api_qf, niveau: :niveau_1) }.destroy!

      get admin_root_path
      expect(modifications.map { it.first(3) }).to include(['Recommandation', 'Bourses → API QF (API)', 'Supprimée'])
    end

    it 'dit qu’aucune modification n’est enregistrée' do
      get admin_root_path
      expect(response.parsed_body.at_css('section[aria-labelledby=dernieres-modifications]').text.squish)
        .to eq('Dernières modifications Aucune modification enregistrée.')
    end

    it 's’arrête à dix fiches' do
      11.times { Vocabulaire.create!(nom: "Vocabulaire #{it}", slug: "vocabulaire-#{it}", categorie: 'usager') }
      get admin_root_path
      expect(modifications.size).to eq(10)
    end
  end

  describe 'dernier rafraîchissement sur le tableau de bord' do
    let(:passage) { SolidQueue::Job.create!(class_name: 'RafraichirCatalogueJob', queue_name: 'default') }

    before { sign_in admin }

    it 'prévient sur la page que l’import remplace les saisies et supprime les fiches créées ici' do
      get admin_root_path
      import = response.parsed_body.at_css('section[aria-labelledby=import]')
      expect(import.at_css('h2').text).to eq('Import depuis Grist et data.gouv')
      expect(import.at_css('.fr-alert--warning').text.squish)
        .to eq('L’import remplace les modifications faites ici par le contenu du Grist et supprime les fiches créées ici.')
    end

    it 'propose de rafraîchir en prévenant que le Grist remplace les saisies' do
      get admin_root_path
      assert_select 'button:not([disabled])', text: 'Rafraîchir depuis Grist et data.gouv'
      expect(response.body).to include('Le contenu du Grist remplacera les modifications faites dans l’administration.')
    end

    it 'signale l’absence de passage récent' do
      get admin_root_path
      expect(response.body).to include('Aucun rafraîchissement récent.')
    end

    it 'signale un passage en cours' do
      passage
      get admin_root_path
      expect(response.body).to include('Dernier rafraîchissement : en cours.')
    end

    it 'désactive le bouton tant qu’un passage est en cours' do
      passage
      get admin_root_path
      assert_select 'button[disabled]', text: 'Rafraîchissement en cours…'
      assert_select 'button:not([disabled])', text: 'Rafraîchir depuis Grist et data.gouv', count: 0
    end

    it 'donne l’heure de Paris d’un passage terminé' do
      passage.update!(finished_at: Time.utc(2026, 10, 5, 12, 30))
      get admin_root_path
      expect(response.body).to include('Dernier rafraîchissement : terminé le 05/10/2026 à 14:30.')
    end

    it 'donne le message d’un passage échoué' do
      passage.failed_with(RuntimeError.new('Grist injoignable'))
      get admin_root_path
      expect(response.body).to include('Dernier rafraîchissement : échoué (Grist injoignable).')
    end
  end

  describe 'POST /admin/rafraichissement' do
    it 'renvoie vers la page de connexion sans admin connecté' do
      post admin_rafraichissement_path
      expect(response).to redirect_to(new_admin_session_path)
      expect(RafraichirCatalogueJob).not_to have_been_enqueued
    end

    it 'lance le rafraîchissement du catalogue et revient au tableau de bord' do
      sign_in admin
      post admin_rafraichissement_path
      expect(RafraichirCatalogueJob).to have_been_enqueued
      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response.body).to include('Rafraîchissement lancé.')
    end
  end

  describe 'POST /admin/connexion' do
    it 'ouvre la session et mène au tableau de bord' do
      post admin_session_path, params: { admin: { email: admin.email, password: 'mot-de-passe-solide' } }
      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<div class="fr-alert fr-alert--info fr-alert--sm">')
      expect(response.body).to include('Connecté.')
    end

    it 'refuse de mauvais identifiants sans quitter le formulaire' do
      post admin_session_path, params: { admin: { email: admin.email, password: 'faux' } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('<div class="fr-alert fr-alert--error fr-alert--sm">')
      expect(response.body).to include('Adresse e-mail ou mot de passe incorrect.')
      expect(response.body).to include('<input class="fr-input" autocomplete="email" type="email" value="dorine@example.gouv.fr" name="admin[email]" id="admin_email" />')
    end
  end

  describe 'outils de l’en-tête' do
    it 'propose la connexion aux visiteurs' do
      get root_path
      expect(Capybara.string(response.body).find_link('Se connecter')[:href]).to eq('/admin/connexion')
      expect(response.body).not_to include('Se déconnecter')
    end

    it 'propose l’administration et la déconnexion aux admins connectés' do
      sign_in admin
      get root_path
      expect(response.body).to include('<a class="fr-btn fr-icon-settings-5-line" href="/admin">Administration</a>')
      expect(response.parsed_body.at_css('form.button_to[method=post][action="/admin/deconnexion"]')).to be_present
      expect(response.body).to include('<button class="fr-btn fr-icon-logout-box-r-line" type="submit">Se déconnecter</button>')
      expect(response.body).not_to include('Se connecter')
    end

    it 'ferme la session et ramène à l’accueil' do
      sign_in admin
      delete destroy_admin_session_path
      expect(response).to redirect_to(root_path)
      get admin_root_path
      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe 'navigation de l’en-tête' do
    def rubriques(nom)
      response.parsed_body.css("nav[aria-label='#{nom}'] .fr-nav__link")
    end

    def entrees_marquees
      response.parsed_body.css("nav[aria-label='Menu de l’administration'] [aria-current]")
        .map { |entree| [entree.text.strip, entree['aria-current']] }
    end

    it 'remplace la navigation du site par les quatre entrées de l’administration' do
      sign_in admin
      get admin_solutions_path
      menu = response.parsed_body.at_css("nav[aria-label='Menu de l’administration']")
      expect(menu.css('.fr-nav__list > .fr-nav__item > .fr-nav__link, .fr-nav__list > .fr-nav__item > .fr-nav__btn')
                 .map { |entree| entree.text.strip })
        .to eq(['À reprendre', 'Démarches', 'Solutions', 'Référentiels'])
      expect(menu.css('.fr-menu .fr-nav__link').map { |lien| lien.text.strip })
        .to eq(['Organisations', 'Fournisseurs de services', 'Vocabulaires'])
      expect(entrees_marquees).to eq([%w[Solutions page]])
      expect(rubriques('Menu principal')).to be_empty
    end

    it 'mène « À reprendre » à l’accueil de l’administration et l’y marque' do
      sign_in admin
      get admin_root_path
      expect(rubriques('Menu de l’administration').find { |lien| lien.text.strip == 'À reprendre' }['href']).to eq(admin_root_path)
      expect(entrees_marquees).to eq([['À reprendre', 'page']])
    end

    it 'marque un référentiel et le bouton de son sous-menu' do
      sign_in admin
      get admin_vocabulaires_path
      expect(entrees_marquees).to eq([%w[Référentiels true], %w[Vocabulaires page]])
    end

    it 'marque la rubrique de la fiche sur sa page d’historique' do
      sign_in admin
      solution = Solution.create!(nom: 'Solution suivie')
      get admin_historique_path(type: 'solutions', id: solution.id)
      expect(entrees_marquees).to eq([%w[Solutions true]])
    end

    it 'garde la liste des recommandations ouverte, sans entrée du menu marquée' do
      sign_in admin
      get admin_recommandations_path
      expect(response).to have_http_status(:ok)
      expect(rubriques('Menu de l’administration').map { |lien| lien.text.strip }).not_to include('Recommandations')
      expect(entrees_marquees).to be_empty
    end

    it 'garde la navigation du site sur les pages publiques d’un admin connecté' do
      sign_in admin
      get root_path
      expect(rubriques('Menu principal').map { |lien| lien.text.strip })
        .to eq(['Accueil', 'Cas d\'usages', 'Articles', 'À propos'])
      expect(rubriques('Menu de l’administration')).to be_empty
    end

    it 'garde la navigation du site sur la page de connexion' do
      get new_admin_session_path
      expect(rubriques('Menu principal')).not_to be_empty
      expect(rubriques('Menu de l’administration')).to be_empty
    end
  end

  describe 'largeur des pages' do
    def hors_fenetres(noeuds) = noeuds.reject { it.ancestors('dialog').any? }
    def conteneurs = hors_fenetres(response.parsed_body.css('.fr-skiplinks, header, main, footer').css('[class~=fr-container]'))
    def a_largeur_du_site(zone = response.parsed_body) = hors_fenetres(zone.css('[class~=fr-container]:not(.fr-container-xl--fluid)'))
    def fluides(zone = response.parsed_body) = hors_fenetres(zone.css('[class~=fr-container-xl--fluid]'))

    it 'élargit les pages de l’admin, leur en-tête et leur pied de page à toute la fenêtre' do
      sign_in admin
      solution = Solution.create!(nom: 'API QF', categorie: 'api')
      ['/admin', '/admin/organisations', "/admin/solutions/#{solution.id}/edit"].each do |chemin|
        get chemin
        expect(conteneurs).to be_present
        expect(a_largeur_du_site).to be_empty, "#{chemin} : #{a_largeur_du_site.map { it['class'] }}"
        expect(conteneurs.map { it['class'] }).to all(include('fr-container-xl--fluid fr-px-md-3w'))
      end
    end

    it 'garde à la page prévisualisée la largeur du site public' do
      sign_in admin
      solution = Solution.create!(nom: 'API QF', categorie: 'api')
      get "/admin/solutions/#{solution.id}/previsualisation"
      expect(a_largeur_du_site(response.parsed_body.at_css('main'))).to be_present
      expect(fluides(response.parsed_body.at_css('main'))).to be_empty
    end

    it 'garde au site public et à la page de connexion leur largeur' do
      [root_path, new_admin_session_path].each do |chemin|
        get chemin
        expect(fluides).to be_empty, chemin
      end
    end
  end

  describe 'GET /admin/connexion' do
    it 'présente le formulaire de connexion en DSFR' do
      get new_admin_session_path
      expect(response.body).to include('<h1>Connexion à l’administration</h1>')
      expect(response.parsed_body.at_css('form.fr-mt-4w[method=post][action="/admin/connexion"]')).to be_present
      expect(response.body).to include('<label class="fr-label" for="admin_email">Adresse e-mail</label>')
      expect(response.body).to include('<label class="fr-label" for="admin_password">Mot de passe</label>')
      expect(response.body).to include('<input class="fr-input" autocomplete="current-password" type="password" name="admin[password]" id="admin_password" />')
      expect(response.body).to include('<label class="fr-label" for="admin_remember_me">Se souvenir de moi</label>')
      expect(response.body).to include('<button type="submit" class="fr-btn">Se connecter</button>')
    end
  end
end
