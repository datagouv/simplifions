require 'rails_helper'

RSpec.describe 'Solutions' do
  describe 'GET /solutions' do
    it 'liste les fiches visibles, API et jeux de données exclus' do
      Solution.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', slug: 'acheteza', visible: true)
      Solution.create!(nom: 'Eovia sans catégorie', slug: 'eovia', visible: true)
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true, uid_datagouv: 'qf')
      Solution.create!(nom: 'Brouillon', categorie: 'brique_logicielle', slug: 'brouillon')

      get solutions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1 class="fr-mb-0">Solutions</h1>')
      expect(response.body.scan('class="fr-card fr-card--no-icon').size).to eq(2)
      expect(response.body).to include('href="/solutions/acheteza"')
      expect(response.body).to include('role="status">2 résultats')
      expect(response.body).not_to include('API Quotient familial')
      expect(response.body).not_to include('Brouillon')
      expect(response.body).not_to include('fr-pagination')
    end
  end

  describe 'contenu de la page' do
    before do
      dinum = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')
      bouquet = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', visible: true,
        slug: 'bouquet-api-particulier', description_courte: 'API distribuant les données des particuliers.',
        site_internet: 'https://particulier.api.gouv.fr/', url_demande_acces: 'https://datapass.example/bouquet',
        permet: "d'accéder aux données **certifiées**", ne_permet_pas: 'le revenu fiscal de référence',
        legende_image: 'Swagger API Particulier', organisations: [dinum],
        cree_le: Time.zone.parse('2025-09-29'), modifie_le: Time.zone.parse('2026-08-26'),
        vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', categorie: 'usager')],
        types_acteurs: [TypeActeur.create!(nom: 'Communes et groupements de communes')])
      bouquet.image.attach(io: StringIO.new('png'), filename: 'swagger.png', content_type: 'image/png')

      api_qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true,
        uid_datagouv: '672cf982fcc8065be6e66f54')
      jeu = Solution.create!(nom: 'Jeu de données RNA', categorie: 'base_de_donnees', visible: true,
        uid_datagouv: 'abc123')
      api_cachee = Solution.create!(nom: 'API cachée', categorie: 'api', uid_datagouv: 'def456')
      api_sans_uid = Solution.create!(nom: 'API sans fiche data.gouv', categorie: 'api', visible: true)
      [api_qf, jeu, api_cachee, api_sans_uid].each do |donnee|
        Integration.create!(integratrice: bouquet, integree: donnee, type_integration: 'expose')
      end
      api_fc = Solution.create!(nom: 'API FranceConnect', categorie: 'api', visible: true, uid_datagouv: 'fc789')
      Integration.create!(integratrice: bouquet, integree: api_fc, type_integration: 'consomme',
        statut: '✅ en production')

      cantine = Demarche.create!(nom: 'Tarification cantine scolaire à 1€', icone: '🥣', visible: true,
        slug: 'tarification-cantine-scolaire-a-1eur', description_courte: 'Communes, simplifiez le dispositif.')
      Recommandation.create!(demarche: cantine, solution: bouquet, niveau: :niveau_2, visible: true)
      Recommandation.create!(demarche: cantine, solution: api_qf, niveau: :niveau_1)

      editeur = Organisation.create!(nom: 'Éditeur SAS', public_ou_prive: 'Privé')
      logiciel = Solution.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true,
        slug: 'acheteza', organisations: [editeur],
        vocabulaires: [Vocabulaire.create!(nom: 'Dites-le-nous une fois', categorie: 'type_simplification')])
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine])
      sans_categorie = Solution.create!(nom: 'Hub sans catégorie', visible: true, slug: 'hub-sans-categorie')
      Integration.create!(integratrice: sans_categorie, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [cantine])
      en_cours = Solution.create!(nom: 'Portail en cours', categorie: 'site_de_consultation', visible: true)
      Integration.create!(integratrice: en_cours, integree: api_qf, type_integration: 'consomme',
        statut: '🚧 en cours', demarches: [cantine])
      portail = Solution.create!(nom: 'Portail agents', categorie: 'site_de_consultation', visible: true,
        slug: 'portail-agents')
      Integration.create!(integratrice: portail, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production')

      get solution_path('bouquet-api-particulier')
    end

    it 'rend l’en-tête et la sidebar' do
      expect(response.body).to include('Bouquet API Particulier')
      expect(response.body).to include('Solution publique')
      expect(response.body).to include('API distribuant les données des particuliers.')
      expect(response.body).to include('Fournisseur')
      expect(response.body).to include('Particuliers')
      expect(response.body).to include('Communes et groupements de communes')
      expect(response.body).to include('Direction interministérielle du numérique')
      expect(response.body).to match(%r{le <time[^>]*>29 septembre 2025\.</time>})
      expect(response.body).to match(%r{Modifié le <time[^>]*>26 août 2026\.</time>})
      expect(response.body).to include('#possibilites-simplification')
      expect(response.body).to include('#donnees-api-utilisees')
      expect(response.body).to include('#donnees-api-fournies')
      expect(response.body).to include('Proposer une modification')
    end

    it 'affiche les CTA vers le site et la demande d’accès, sans use_case' do
      expect(response.body).to include('href="https://particulier.api.gouv.fr/"')
      expect(response.body).to include('href="https://datapass.example/bouquet"')
      expect(response.body).to include('Site de la solution')
      expect(response.body).to include('Demande d’accès')
    end

    it 'affiche l’image d’exemple avec sa légende' do
      expect(response.body).to include('<figcaption')
      expect(response.body).to include('Swagger API Particulier')
      expect(response.body).to include('swagger.png')
    end

    it 'rend les possibilités de simplification en markdown' do
      expect(response.body).to include('<strong>certifiées</strong>')
      expect(response.body).to include('Périmètre de simplification non couvert')
      expect(response.body).to include('le revenu fiscal de référence')
    end

    it 'liste les cas d’usages simplifiables en tuiles' do
      expect(response.body).to include('🥣 Tarification cantine scolaire à 1€')
      expect(response.body).to include('href="/demarches/tarification-cantine-scolaire-a-1eur"')
      expect(response.body).to include('Communes, simplifiez le dispositif.')
    end

    it 'liste les données et API fournies et utilisées, visibles et référencées sur data.gouv seulement' do
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/672cf982fcc8065be6e66f54')
      expect(response.body).to include('https://www.data.gouv.fr/fr/datasets/abc123')
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/fc789')
      expect(response.body).to include('À définir')
      expect(response.body).to include('https://placehold.co/40x40')
      expect(response.body).to include('Voir le jeu de données sur Data.gouv.fr')
      expect(response.body).not_to include('API cachée')
      expect(response.body).not_to include('API sans fiche data.gouv')
      expect(response.body).not_to include('Aucun jeu de données ou API utilisé ou fourni')
    end

    it 'rend les solutions intégratrices en onglets, avec lien, badge, tags et indicateur' do
      expect(response.body).to include('id="solutions-integratices"')
      expect(response.body).to include('Solutions intégrant "Bouquet API Particulier"')
      expect(response.body).to include('Logiciels métiers (1)')
      expect(response.body).to include('Sites de consultation (1)')
      expect(response.body).to include('href="/solutions/acheteza"')
      expect(response.body).to include('Solution privée')
      expect(response.body).to include('Dites-le-nous une fois')
      expect(response.body).to include('1/1')
      expect(response.body).not_to include('Portail en cours')
      expect(response.body).not_to include('Hub sans catégorie')
      expect(response.body).to include('2 solutions disponibles')
      expect(response.body).to include('Trier par')
    end

    it 'propose une modification du contenu' do
      expect(response.body).to include('Proposer une modification du contenu')
      expect(response.body).to include('de cette solution')
    end
  end

  describe 'GET /solutions/:slug' do
    it 'rend la solution visible, avec les fallbacks des contenus absents' do
      Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle',
        slug: 'bouquet-api-particulier', visible: true)

      get solution_path('bouquet-api-particulier')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Bouquet API Particulier')
      expect(response.body).to include('Non renseigné')
      expect(response.body).to include('Aucun lien vers un site officiel actuellement.')
      expect(response.body).to include("Aucun cas d'usage n'est référencé pour cette solution actuellement.")
      expect(response.body).to include('Aucun jeu de données ou API utilisé ou fourni')
    end

    it 'n’affiche pas le bloc « Données et API » vide quand des API sont utilisées mais aucune fournie' do
      logiciel = Solution.create!(nom: 'Logiciel RH', categorie: 'logiciel_metier_cle_en_main', visible: true,
        slug: 'logiciel-rh')
      api = Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true, uid_datagouv: 'qf1')
      Integration.create!(integratrice: logiciel, integree: api, type_integration: 'consomme',
        statut: '✅ en production')

      get solution_path('logiciel-rh')

      expect(response.body).to include('Données et API utilisées')
      expect(response.body).not_to include('Aucun jeu de données ou API utilisé ou fourni')
      expect(response.body).not_to include('id="donnees-api"')
    end

    it 'n’affiche pas la section intégratrices quand aucune n’a de catégorie mappée' do
      bouquet = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', visible: true,
        slug: 'bouquet-api-particulier')
      api = Solution.create!(nom: 'API Quotient familial', categorie: 'api')
      Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
      hub = Solution.create!(nom: 'Hub sans catégorie', visible: true, slug: 'hub-sans-categorie')
      Integration.create!(integratrice: hub, integree: api, type_integration: 'consomme',
        statut: '✅ en production')

      get solution_path('bouquet-api-particulier')

      expect(response.body).not_to include('Solutions intégrant')
      expect(response.body).not_to include('#solutions-integratices')
    end

    it 'renvoie 404 pour une solution non visible' do
      Solution.create!(nom: 'Brouillon', categorie: 'brique_logicielle', slug: 'brouillon', visible: false)

      get solution_path('brouillon')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour un slug inconnu' do
      get solution_path('nexiste-pas')

      expect(response).to have_http_status(:not_found)
    end

    it 'renvoie 404 pour une API, qui n’a pas de page' do
      Solution.create!(nom: 'API Quotient familial', categorie: 'api', visible: true)

      get solution_path('api-quotient-familial')

      expect(response).to have_http_status(:not_found)
    end
  end
end
