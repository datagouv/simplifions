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
