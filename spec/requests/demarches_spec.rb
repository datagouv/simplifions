require 'rails_helper'

RSpec.describe 'Demarches' do
  describe 'GET /demarches/:slug' do
    it 'rend la démarche visible' do
      Demarche.create!(nom: 'Tarification cantine scolaire à 1€', slug: 'tarification-cantine-scolaire-a-1eur',
        visible: true)

      get demarche_path('tarification-cantine-scolaire-a-1eur')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Tarification cantine scolaire à 1€')
    end

    it 'renvoie 404 pour une démarche non visible' do
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon', visible: false)

      get demarche_path('brouillon')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour un slug inconnu' do
      get demarche_path('nexiste-pas')

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'contenu de la page' do
    before do
      demarche = Demarche.create!(nom: 'Tarification cantine scolaire à 1€', icone: '🥣',
        slug: 'tarification-cantine-scolaire-a-1eur', visible: true,
        cree_le: Time.zone.parse('2025-09-29'), modifie_le: Time.zone.parse('2026-08-26'),
        description_courte: 'Communes, simplifiez la mise en œuvre du dispositif.',
        contexte: 'Une grille tarifaire **progressive** est requise.',
        cadre_juridique: 'Voir [R.531-52](https://legifrance.gouv.fr/codes/article_lc/LEGIARTI000039036672).',
        vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', categorie: 'usager'),
                       Vocabulaire.create!(nom: 'Dites-le-nous une fois', categorie: 'type_simplification')],
        types_acteurs: [TypeActeur.create!(nom: 'Communes et groupements de communes')])

      bouquet = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', visible: true,
        slug: 'bouquet-api-particulier', url_demande_acces: 'https://datapass.api.gouv.fr/api-particulier')
      api_qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api', uid_datagouv: '672cf982fcc8065be6e66f54')
      logiciel = Solution.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true,
        slug: 'acheteza')

      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [demarche])

      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true,
        donnees_utiles: '- quotient familial CAF ou MSA', parametres_a_saisir: 'État civil')
      brouillon = Solution.create!(nom: 'Reco brouillon', categorie: 'brique_logicielle')
      Recommandation.create!(demarche:, solution: brouillon, niveau: :niveau_2, visible: false)
      Recommandation.create!(demarche:, solution: api_qf, niveau: :niveau_1, ordre: 1, visible: true,
        description: 'Le quotient familial du mois courant.')

      get demarche_path('tarification-cantine-scolaire-a-1eur')
    end

    it 'rend l’en-tête et la sidebar' do
      expect(response.body).to include('🥣')
      expect(response.body).to include('Communes, simplifiez la mise en œuvre du dispositif.')
      expect(response.body).to include('Particuliers')
      expect(response.body).to include('Communes et groupements de communes')
      expect(response.body).to include('Direction interministérielle du numérique')
      expect(response.body).to include('Proposer une modification')
    end

    it 'rend les sections contexte et cadre juridique en markdown' do
      expect(response.body).to include('<strong>progressive</strong>')
      expect(response.body).to include('href="https://legifrance.gouv.fr/codes/article_lc/LEGIARTI000039036672"')
    end

    it 'rend un bloc « Données disponibles » par recommandation de niveau 2 visible, même si un niveau 1 est visible' do
      expect(response.body.scan('Via «').size).to eq(1)
      expect(response.body).not_to include('Reco brouillon')
      expect(response.body).to include('Bouquet API Particulier')
      expect(response.body).to include('quotient familial CAF ou MSA')
      expect(response.body).to include('État civil')
      expect(response.body)
        .to include('https://datapass.api.gouv.fr/api-particulier?use_case=tarification-cantine-scolaire-a-1eur')
    end

    it 'rend la matrice des moyens d’accès, accordéons vides grisés' do
      expect(response.body).to include('Acheteza')
      expect(response.body).to include('Sans développement')
      expect(response.body.scan('Aucune solution référencée').size).to eq(2)
    end

    it 'ne pointe vers aucune page solution tant qu’elles n’existent pas' do
      expect(response.body).not_to include('href="/solutions/')
    end

    it 'affiche les dates de création et de modification en français' do
      expect(response.body).to match(%r{le <time[^>]*>29 septembre 2025\.</time>})
      expect(response.body).to match(%r{Modifié le <time[^>]*>26 août 2026\.</time>})
    end

    it 'liste les API et données utiles du niveau 1 avec leurs descriptions, filtrables' do
      expect(response.body).to include('API Quotient familial')
      expect(response.body).to include('Le quotient familial du mois courant.')
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/672cf982fcc8065be6e66f54')
      expect(response.body).to include('Filtrer les endpoints')
    end
  end

  describe 'anciennes URLs /cas-d-usages' do
    it 'redirige en 301 vers /demarches/:slug' do
      get '/cas-d-usages/tarification-cantine-scolaire-a-1eur'

      expect(response).to redirect_to('/demarches/tarification-cantine-scolaire-a-1eur')
      expect(response).to have_http_status(:moved_permanently)
    end

    it 'redirige l’ancien slug publié de suivi-des-tiers-aides vers le nouveau' do
      get '/cas-d-usages/aides-publiques-personnes-morales-et-entreprises-individuelles-suivi-des-tiers-aides'

      expect(response).to redirect_to('/demarches/aides-publiques-entreprises-et-associations-suivi-des-tiers-aides')
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
