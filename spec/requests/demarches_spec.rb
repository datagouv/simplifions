require 'rails_helper'

RSpec.describe 'Demarches' do
  describe 'GET /demarches' do
    before do
      21.times { |i| Demarche.create!(nom: "Démarche #{i}", slug: "demarche-#{i}", visible: true) }
      Demarche.create!(nom: 'Brouillon invisible', slug: 'brouillon')
    end

    it 'liste les démarches visibles par pages de 20, avec compteur et pagination' do
      get demarches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1 class="fr-mb-0">Cas d&#39;usages</h1>')
      expect(response.body.scan('class="demarche-card').size).to eq(20)
      expect(response.body).to include('href="/demarches/demarche-0"')
      expect(response.body).to include('role="status">21 résultats')
      expect(response.body).to include('fr-pagination')
      expect(response.body).to include('href="/demarches?page=2"')
      expect(response.body).not_to include('Brouillon invisible')
    end

    it 'rend chaque carte comme le site : titre, chapo, usagers et acteurs triés' do
      Demarche.create!(nom: 'Cantine à 1€', icone: '🥣', slug: 'cantine', visible: true,
        description_courte: "Communes, simplifiez.\nDeuxième ligne ignorée.",
        vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')],
        types_acteurs: [TypeActeur.create!(nom: 'Départements'), TypeActeur.create!(nom: 'Communes')])

      get demarches_path(q: 'cantine')

      expect(response.body).to include('🥣 Cantine à 1€')
      expect(response.body).to include('Communes, simplifiez.')
      expect(response.body).not_to include('Deuxième ligne')
      expect(response.body).to include('Pour simplifier les démarches des <b>Particuliers</b>')
      expect(response.body).to include('fr-text--right')
      expect(response.body).to include('À destination des <b>Communes</b> et <b>Départements</b>')
    end

    it 'propose les facettes du site préremplies et le passage aux solutions avec la même requête' do
      communes = TypeActeur.create!(nom: 'Communes', slugs: %w[communes tout-acteurs-publics])
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      Vocabulaire.create!(nom: '💠💠 DLNUF', slug: 'dlnuf', categorie: 'type_simplification')
      Vocabulaire.create!(nom: 'Brique technique', slug: 'brique-technique', categorie: 'solution')
      Solution.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', slug: 'acheteza', visible: true,
        description_courte: 'Démarches des communes', types_acteurs: [communes])
      Demarche.find_by!(slug: 'demarche-0').update!(types_acteurs: [communes])

      get demarches_path('fournisseurs-de-service' => 'communes', 'sort' => '-created', 'q' => 'Démarche')

      expect(response.body).to include('<option selected="selected" value="communes">Communes et groupements de communes</option>')
      expect(response.body).to include('<option value="particuliers">Particuliers</option>')
      expect(response.body).to include('<option value="dlnuf">Dites-le nous une fois</option>')
      expect(response.body).to include('<option value="brique-technique">API, jeu de données ou brique logicielle</option>')
      expect(response.body).to include('<option selected="selected" value="-created">Date de création</option>')
      expect(response.body).to include('role="status">1 résultat<')
      expect(response.body).to include('href="/solutions?fournisseurs-de-service=communes&amp;q=D%C3%A9marche&amp;sort=-created"')
      expect(response.body).to match(%r{Solutions</span>\s*<span class="fr-badge[^>]*>1</span>})
      expect(response.body).to include('data-controller="form"')
      expect(response.body).to include('data-action="change-&gt;form#submit"')
    end

    it 'ramène une page hors plage à la dernière, sans pagination quand tout tient sur une page' do
      get demarches_path(page: 2, q: 'Démarche 20')

      expect(response.body.scan('class="demarche-card').size).to eq(1)
      expect(response.body).to include('role="status">1 résultat<')
      expect(response.body).not_to include('fr-pagination')
    end

    it 'garde les liens de pagination sur /demarches quels que soient les paramètres reçus' do
      get '/demarches?host=evil.com&protocol=ftp&controller=articles&action=show&script_name=/x&page=1'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('href="/demarches?page=2"')
      expect(response.body).not_to include('evil.com')
      expect(response.body).to match(/fr-pagination__link--first[^>]*aria-disabled="true"/)
      expect(response.body).not_to match(/fr-pagination__link--first[^>]*aria-current/)
      expect(response.body).to match(/aria-current="page"[^>]*title="Page 1"|title="Page 1"[^>]*aria-current="page"/)
    end

    it 'remplace la liste vide par l’invitation à réinitialiser les filtres, comme le site' do
      get demarches_path(q: 'zzzz', 'target-users' => 'particuliers')

      expect(response.body).to include("Vous n'avez pas trouvé ce que vous cherchez ?")
      expect(response.body).to include('Essayez de réinitialiser les filtres pour élargir votre recherche.')
      expect(response.body).to include('href="/demarches"')
      expect(response.body).to include('Réinitialiser les filtres')
      expect(response.body).to include('magnifying_glass')
      expect(response.body).not_to include('role="status"')
      expect(response.body).not_to include('Trier par')
      expect(response.body).not_to include('class="demarche-card')
    end

    it 'accepte la valeur en forme tag publiée par le site actuel' do
      communes = TypeActeur.create!(nom: 'Communes', slugs: %w[communes])
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      Demarche.find_by!(slug: 'demarche-0').update!(types_acteurs: [communes],
        vocabulaires: [Vocabulaire.find_by!(slug: 'particuliers')])

      get demarches_path('target-users' => 'simplifions-v2-target-users-particuliers',
        'fournisseurs-de-service' => 'simplifions-v2-fournisseurs-de-service-communes')

      expect(response.body).to include('role="status">1 résultat<')
      expect(response.body).to include('href="/demarches/demarche-0"')
    end

    it 'ignore les paramètres non scalaires ou hors plage' do
      get '/demarches?page[]=1&target-users[a]=b&q[]=x&sort[]=y'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('role="status">21 résultats')

      get '/demarches?page=99999999999999999999999'
      expect(response).to have_http_status(:ok)
      expect(response.body.scan('class="demarche-card').size).to eq(1)
    end
  end

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
        slug: 'bouquet-api-particulier', uid_datagouv: 'bouquet1',
        url_demande_acces: 'https://datapass.api.gouv.fr/api-particulier')
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

    it 'fait pointer les intégratrices de la matrice vers leur page solution' do
      expect(response.body).to include('href="/solutions/acheteza"')
    end

    it 'affiche les dates de création et de modification en français' do
      expect(response.body).to match(%r{le <time[^>]*>29 septembre 2025\.</time>})
      expect(response.body).to match(%r{Modifié le <time[^>]*>26 août 2026\.</time>})
    end

    it 'liste les API et données utiles du niveau 1 avec leurs descriptions, filtrables' do
      expect(response.body).to include('API Quotient familial')
      expect(response.body).to include('Le quotient familial du mois courant.')
      expect(response.body).to match(%r{<h6[^>]*>\s*<a[^>]*dataservices/bouquet1})
      expect(response.body).to include('À définir')
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/672cf982fcc8065be6e66f54')
      expect(response.body).to include('Filtrer les endpoints')
    end
  end

  describe 'anciennes URLs /cas-d-usages' do
    it 'redirige la liste en 301 vers /demarches en conservant les filtres' do
      get '/cas-d-usages?target-users=particuliers'

      expect(response).to redirect_to('/demarches?target-users=particuliers')
      expect(response).to have_http_status(:moved_permanently)
    end

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
