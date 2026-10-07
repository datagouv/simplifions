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

    it 'affiche le tableau de bord une fois connecté' do
      sign_in admin
      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1>Administration</h1>')
      expect(response.parsed_body.css('.fr-breadcrumb__list li').map { |etape| etape.text.strip }).to eq(['Administration'])
    end

    it 'mène à chaque table du catalogue' do
      sign_in admin
      get admin_root_path
      %w[demarches solutions recommandations integrations organisations types_acteurs vocabulaires].each do |chemin|
        expect(response.body).to include("href=\"/admin/#{chemin}\"")
      end
    end
  end

  describe 'dernier rafraîchissement sur le tableau de bord' do
    let(:passage) { SolidQueue::Job.create!(class_name: 'RafraichirCatalogueJob', queue_name: 'default') }

    before { sign_in admin }

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
      expect(response.body).to include('<a class="fr-btn fr-icon-lock-line" href="/admin/connexion">Se connecter</a>')
      expect(response.body).not_to include('Se déconnecter')
    end

    it 'propose l’administration et la déconnexion aux admins connectés' do
      sign_in admin
      get root_path
      expect(response.body).to include('<a class="fr-btn fr-icon-settings-5-line" href="/admin">Administration</a>')
      expect(response.body).to include('<form class="button_to" method="post" action="/admin/deconnexion">')
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

    it 'remplace la navigation du site par les rubriques de l’administration' do
      sign_in admin
      get admin_solutions_path
      expect(rubriques('Menu de l’administration').map { |lien| lien.text.strip })
        .to eq(['Démarches', 'Solutions', 'Recommandations', 'Intégrations', 'Organisations',
                'Fournisseurs de services', 'Vocabulaires'])
      expect(rubriques('Menu de l’administration').filter_map { |lien| [lien.text, lien['aria-current']] if lien['aria-current'] })
        .to eq([%w[Solutions page]])
      expect(rubriques('Menu principal')).to be_empty
    end

    it 'marque la rubrique de la fiche sur sa page d’historique' do
      sign_in admin
      solution = Solution.create!(nom: 'Solution suivie')
      get admin_historique_path(type: 'solutions', id: solution.id)
      expect(rubriques('Menu de l’administration').filter_map { |lien| [lien.text, lien['aria-current']] if lien['aria-current'] })
        .to eq([%w[Solutions true]])
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

  describe 'GET /admin/connexion' do
    it 'présente le formulaire de connexion en DSFR' do
      get new_admin_session_path
      expect(response.body).to include('<h1>Connexion à l’administration</h1>')
      expect(response.body).to include('<form class="fr-mt-4w" action="/admin/connexion" accept-charset="UTF-8" method="post">')
      expect(response.body).to include('<label class="fr-label" for="admin_email">Adresse e-mail</label>')
      expect(response.body).to include('<label class="fr-label" for="admin_password">Mot de passe</label>')
      expect(response.body).to include('<input class="fr-input" autocomplete="current-password" type="password" name="admin[password]" id="admin_password" />')
      expect(response.body).to include('<label class="fr-label" for="admin_remember_me">Se souvenir de moi</label>')
      expect(response.body).to include('<button type="submit" class="fr-btn">Se connecter</button>')
    end
  end
end
