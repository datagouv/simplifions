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
      expect(response.body).to include('<section id="list"')
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

    it 'ne reprend dans les liens de pagination que les filtres du catalogue' do
      get '/demarches?q=demarche&params[q]=autre&foo=bar'

      expect(response.parsed_body.at_css('.fr-pagination a[title="Page 2"]')['href']).to eq('/demarches?page=2&q=demarche')
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
        vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager'),
                       Vocabulaire.create!(nom: 'Dites-le-nous une fois', slug: 'dites-le-nous-une-fois', categorie: 'type_simplification')],
        types_acteurs: [TypeActeur.create!(nom: 'Communes et groupements de communes')])

      bouquet = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', visible: true,
        slug: 'bouquet-api-particulier', uid_datagouv: 'bouquet1', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')],
        url_demande_acces: 'https://datapass.api.gouv.fr/api-particulier',
        datagouv_titre: 'Bouquet API Particulier (data.gouv)', datagouv_acces: 'restricted',
        datagouv_acces_acteurs_publics: 'yes', datagouv_logo: 'https://avatars.test/dinum-100.png')
      api_qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api', uid_datagouv: '672cf982fcc8065be6e66f54')
      logiciel = Solution.create!(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true,
        slug: 'acheteza', types_solution: ['Profil acheteur', 'Portail agent'])

      api_statut = Solution.create!(nom: 'API Statut étudiant', categorie: 'api')
      autre_demarche = Demarche.create!(nom: 'Bourse', slug: 'bourse', visible: true)

      Integration.create!(integratrice: bouquet, integree: api_qf, type_integration: 'expose')
      Integration.create!(integratrice: bouquet, integree: api_statut, type_integration: 'expose')

      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true,
        donnees_utiles: '- quotient familial CAF ou MSA', parametres_a_saisir: 'État civil')
      brouillon = Solution.create!(nom: 'Reco brouillon', categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      Recommandation.create!(demarche:, solution: brouillon, niveau: :niveau_2, visible: false)
      Recommandation.create!(demarche:, solution: api_qf, niveau: :niveau_1, ordre: 1, visible: true,
        description: 'Le quotient familial du mois courant.')
      Recommandation.create!(demarche:, solution: api_statut, niveau: :niveau_1, ordre: 2, visible: true)
      Recommandation.create!(demarche: autre_demarche, solution: api_statut, niveau: :niveau_1)
      Integration.create!(integratrice: logiciel, integree: api_qf, type_integration: 'consomme',
        statut: '✅ en production', demarches: [demarche])
      Integration.create!(integratrice: logiciel, integree: api_statut, type_integration: 'consomme',
        statut: '✅ en production', demarches: [autre_demarche])

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

    it 'rend chaque intégratrice en carte : titre vers la fiche, types de solution, données utiles intégrées toutes démarches confondues' do
      carte = Capybara.string(response.body).find('#donnees-disponibles .solution-integratrice-card', text: 'Acheteza')

      expect(carte).to have_link('Acheteza', href: '/solutions/acheteza')
      expect(carte).to have_link('Voir la fiche Acheteza', href: '/solutions/acheteza')
      expect(carte).to have_text('Profil acheteur • Portail agent')
      expect(carte).to have_css('.indicator--green', text: '2/2')
      expect(carte).to have_text('API ou jeu de données utiles Bouquet API Particulier')
      expect(carte[:class]).not_to include('fr-enlarge-link')
    end

    it 'propose « Plus d’informations » vers la fiche de la solution recommandée, avant la demande d’accès' do
      bouton = %r{<a class="fr-btn fr-btn--secondary" href="/solutions/bouquet-api-particulier">Plus d&#39;informations sur Bouquet API Particulier</a>}
      expect(response.body).to match(bouton)
      expect(response.body.index('Plus d&#39;informations sur')).to be < response.body.index('Demander un accès pour ce cas')
    end

    it 'fait pointer les intégratrices de la matrice vers leur page solution' do
      expect(response.body).to include('href="/solutions/acheteza"')
    end

    it 'affiche les dates de création et de modification en français' do
      expect(response.body).to match(%r{le <time[^>]*>29 septembre 2025\.</time>})
      expect(response.body).to match(%r{Modifié le <time[^>]*>26 août 2026\.</time>})
    end

    it 'date la modification à l’heure de Paris, lendemain d’une modification à 23 h 30 UTC' do
      Demarche.create!(nom: 'Aides', slug: 'aides', visible: true, modifie_le: Time.utc(2026, 8, 26, 23, 30))
      get '/demarches/aides'
      expect(response.body).to include('Modifié le <time datetime="2026-08-27T01:30:00+02:00">27 août 2026.</time>')
    end

    it 'liste les API et données utiles du niveau 1 avec leurs descriptions, filtrables' do
      expect(response.body).to include('API Quotient familial')
      expect(response.body).to include('Le quotient familial du mois courant.')
      expect(response.body).to match(%r{<h6[^>]*>\s*<a[^>]*dataservices/bouquet1})
      expect(response.body).to include('Bouquet API Particulier (data.gouv)')
      expect(response.body).to include('API restreinte · accessible aux acteurs publics')
      expect(response.body).to include('src="https://avatars.test/dinum-100.png"')
      expect(response.body).to include('https://www.data.gouv.fr/fr/dataservices/672cf982fcc8065be6e66f54')
      expect(response.body).to include('Filtrer les endpoints')
    end
  end

  describe 'carte d’une intégratrice d’une seule donnée utile' do
    it 'montre une coche verte au lieu de 1/1' do
      demarche = Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true)
      api_bodacc = Solution.create!(nom: 'API BODACC', categorie: 'api')
      bouquet = Solution.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle',
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      Integration.create!(integratrice: bouquet, integree: api_bodacc, type_integration: 'expose')
      logiciel = Solution.create!(nom: 'Acheteza', slug: 'acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true)
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true)
      Recommandation.create!(demarche:, solution: api_bodacc, niveau: :niveau_1, visible: true)
      Integration.create!(integratrice: logiciel, integree: api_bodacc, type_integration: 'consomme',
        statut: '✅ en production', demarches: [demarche])

      get demarche_path('marches-publics')

      carte = Capybara.string(response.body).find('#donnees-disponibles .solution-integratrice-card', text: 'Acheteza')
      expect(carte).to have_css('.indicator--green.fr-icon-check-line')
      expect(carte).to have_text('Donnée utile de « Bouquet API Entreprise » intégrée')
      expect(carte).to have_no_text('1/1')
    end
  end

  describe 'modale des données intégrées par une solution' do
    before do
      demarche = Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true)
      dinum = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')
      entreprise = Solution.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle', organisations: [dinum])
      particulier = Solution.create!(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', organisations: [dinum])
      bodacc = Solution.create!(nom: 'API BODACC', categorie: 'api', uid_datagouv: 'bodacc1',
        datagouv_acces: 'open', datagouv_organisation: 'DILA')
      bio = Solution.create!(nom: 'API professionnels BIO', categorie: 'api')
      qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api')
      en_attente = Solution.create!(nom: 'API pas encore publiée', categorie: 'api')
      [bodacc, bio, en_attente].each { Integration.create!(integratrice: entreprise, integree: it, type_integration: 'expose') }
      Integration.create!(integratrice: particulier, integree: qf, type_integration: 'expose')
      Recommandation.create!(demarche:, solution: entreprise, niveau: :niveau_2, visible: true, ordre: 1)
      Recommandation.create!(demarche:, solution: particulier, niveau: :niveau_2, visible: true, ordre: 2)
      [bodacc, bio, qf].each { Recommandation.create!(demarche:, solution: it, niveau: :niveau_1, visible: true) }
      Recommandation.create!(demarche:, solution: en_attente, niveau: :niveau_1, brouillon: { 'visible' => '1' })

      acheteza = Solution.create!(nom: 'Acheteza', slug: 'acheteza', categorie: 'logiciel_metier_cle_en_main', visible: true,
        organisations: [Organisation.create!(nom: 'Éditeur SAS', public_ou_prive: 'Privé')])
      [bodacc, qf, en_attente].each do |api|
        Integration.create!(integratrice: acheteza, integree: api, type_integration: 'consomme',
          statut: '✅ en production', demarches: [demarche])
      end
      Integration.create!(integratrice: acheteza, integree: bio, type_integration: 'consomme',
        statut: '⚙️ en développement', demarches: [demarche])
      sirene = Solution.create!(nom: 'API Sirene', categorie: 'api')
      Recommandation.create!(demarche:, solution: sirene, niveau: :niveau_2, visible: true, ordre: 3)
      Integration.create!(integratrice: acheteza, integree: sirene, type_integration: 'consomme',
        statut: '✅ en production', demarches: [demarche])

      get demarche_path('marches-publics')
    end

    let(:page) { Capybara.string(response.body) }
    let(:modale) { page.find('dialog.fr-modal', visible: :all) }

    it 'est ouverte par l’œil de chaque carte de la solution, même sans compteur, une seule fois pour la page' do
      boutons = page.all('.solution-integratrice-card button', text: 'Voir les données intégrées par Acheteza')

      expect(boutons.size).to eq(4)
      expect(boutons.pluck('aria-controls').uniq).to eq([modale[:id]])
      expect(page).to have_css('dialog.fr-modal', count: 1, visible: :all)
    end

    it 'nomme la solution, son opérateur et compte par donnée recommandée puis au total' do
      texte = modale.text(:all).squish

      expect(modale).to have_css('h2', text: 'Acheteza', visible: :all)
      expect(texte).to include('Solution privée | Éditeur SAS')
      expect(texte).to include('Bouquet API Entreprise 1/2')
      expect(texte).to include('Bouquet API Particulier 1/1')
      expect(texte).to include("2/3 API et jeux de données utiles pour ce cas d'usage")
    end

    it 'coche chaque donnée utile intégrée, avec son lien data.gouv, sans la donnée qui attend sa publication' do
      texte = modale.text(:all).squish

      expect(texte).to include('API BODACC : intégrée')
      expect(modale.find('li', text: 'API BODACC', visible: :all).text(:all)).to include('API ouverte').and include('DILA')
      expect(texte).to include('API professionnels BIO : non intégrée')
      expect(texte).to include('API Quotient familial : intégrée')
      expect(modale).to have_link('Voir sur data.gouv.fr API BODACC - nouvelle fenêtre', href: 'https://www.data.gouv.fr/fr/dataservices/bodacc1', visible: :all)
      expect(response.body).not_to include('API pas encore publiée')
    end

    it 'montre sur la carte le même compte que son groupe dans la modale' do
      bloc = page.find('.reco-card', text: 'Bouquet API Entreprise', match: :first)
      compte_carte = bloc.find('.solution-integratrice-card', text: 'Acheteza', visible: :all)
        .first('.integration-indicator__count', visible: :all).text(:all)
      compte_groupe = modale.find('h3', text: 'Bouquet API Entreprise', visible: :all).find('span', visible: :all).text(:all)

      expect(compte_carte).to eq('1/2')
      expect(compte_groupe).to eq(compte_carte)
    end
  end

  describe 'onglets du cas d’usage' do
    let(:demarche) { Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true) }
    let(:page) { Capybara.string(response.body) }
    let(:onglet_solutions) { page.find('#solutions-integratrices', visible: :all) }

    def integratrice(nom, categorie, *apis)
      solution = Solution.create!(nom:, categorie:, slug: nom.parameterize, visible: true)
      apis.each do |api|
        Integration.create!(integratrice: solution, integree: api, type_integration: 'consomme', statut: '✅ en production', demarches: [demarche])
      end
    end

    def recommande(*apis)
      bouquet = Solution.create!(nom: 'Bouquet API Entreprise', categorie: 'brique_logicielle',
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      apis.each { Integration.create!(integratrice: bouquet, integree: it, type_integration: 'expose') }
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true, ordre: 1)
      apis.each { Recommandation.create!(demarche:, solution: it, niveau: :niveau_1, visible: true) }
      bouquet
    end

    describe 'avec des solutions ayant intégré des données utiles' do
      before do
        bodacc = Solution.create!(nom: 'API BODACC', categorie: 'api')
        bio = Solution.create!(nom: 'API professionnels BIO', categorie: 'api')
        bouquet = recommande(bodacc, bio)
        Recommandation.create!(demarche:, solution: Solution.create!(nom: 'API Sirene', categorie: 'api'), niveau: :niveau_2, visible: true, ordre: 2)
        integratrice('Acheteza', 'logiciel_metier_cle_en_main', bodacc)
        integratrice('Brique marchés', 'brique_logicielle', bio)
        integratrice('Zeta', 'logiciel_metier_cle_en_main', bodacc, bio)
        integratrice('Sans donnée', 'logiciel_metier_cle_en_main', bouquet)

        get demarche_path('marches-publics')
      end

      it 'sépare les données disponibles et les solutions en deux onglets comptés' do
        expect(page).to have_css('[role=tab][aria-controls=donnees-disponibles]', text: 'Données disponibles et utiles (2)')
        expect(page).to have_css('[role=tab][aria-controls=solutions-integratrices]:not([disabled])', text: 'Solutions ayant intégré ces données (3)')
        expect(page).to have_css('#donnees-disponibles[role=tabpanel] .reco-card', count: 2)
        expect(page).to have_css('nav.fr-summary a[href="#solutions-integratrices"]', text: 'Solutions ayant intégré ces données')
      end

      it 'range les solutions par catégorie, les plus intégrées d’abord, sous la règle de tri écrite' do
        texte = onglet_solutions.text(:all).squish
        regle = 'Les solutions sont classées de celle qui a intégré le plus de données utiles à celle qui en a intégré le moins, puis par ordre alphabétique.'

        expect(texte).to include(regle)
        expect(onglet_solutions.all('.fr-accordion__btn', visible: :all).map { it.text(:all).squish })
          .to eq(['Logiciel métier « clé en main »', 'Brique logicielle à intégrer'])
        expect(onglet_solutions.all('.solution-integratrice-card__title', visible: :all).map { it.text(:all).squish })
          .to eq(['Zeta', 'Acheteza', 'Brique marchés'])
        expect(texte.index(regle)).to be < texte.index('Zeta')
      end

      it 'compte sur chaque carte les données intégrées sur le total du cas d’usage, avec l’œil vers sa modale' do
        carte = onglet_solutions.find('.solution-integratrice-card', text: 'Acheteza', visible: :all)

        expect(carte).to have_css('.integration-indicator__count', text: '1/2', visible: :all)
        expect(carte.text(:all)).to include("API et jeux de données utiles du cas d'usage")
        expect(carte).to have_css("button[aria-controls='#{page.find('dialog', text: 'Acheteza', visible: :all)[:id]}']", visible: :all)
      end

      it 'propose d’afficher les solutions en cartes, choisies d’office, ou en tableau' do
        choix = onglet_solutions.find('fieldset', text: 'Affichage des solutions', visible: :all)

        expect(choix).to have_field('Cartes', type: 'radio', checked: true, visible: :all)
        expect(choix).to have_field('Tableau', type: 'radio', checked: false, visible: :all)
      end

      it 'compare dans un tableau par catégorie les données intégrées par chaque solution' do
        tableaux = onglet_solutions.all('table', visible: :all)
        lignes = tableaux.map do |tableau|
          tableau.all('tbody tr', visible: :all).map { |ligne| ligne.all('th, td', visible: :all).map { it.text(:all).squish } }
        end

        expect(tableaux.map { it.find('caption', visible: :all).text(:all).squish })
          .to eq(['Logiciel métier « clé en main »', 'Brique logicielle à intégrer'])
        expect(tableaux.first.all('thead th[scope=col]', visible: :all).map { it.text(:all).squish })
          .to eq(['Solution', 'Données intégrées', 'API BODACC', 'API professionnels BIO'])
        expect(lignes).to eq([
          [['Zeta', '2/2', 'Intégrée', 'Intégrée'], ['Acheteza', '1/2', 'Intégrée', 'Non intégrée']],
          [['Brique marchés', '1/2', 'Non intégrée', 'Intégrée']]
        ])
        expect(tableaux.first.all('tbody th[scope=row]', visible: :all).map { it.text(:all).squish }).to eq(%w[Zeta Acheteza])
      end

      it 'rend chaque modale une seule fois, hors des onglets' do
        expect(page).to have_css('dialog.fr-modal', count: 4, visible: :all)
        expect(page).to have_no_css('[role=tabpanel] dialog', visible: :all)
      end
    end

    it 'dit « Donnée utile du cas d’usage intégrée » pour une solution qui a intégré l’unique donnée utile' do
      bodacc = Solution.create!(nom: 'API BODACC', categorie: 'api')
      recommande(bodacc)
      integratrice('Acheteza', 'logiciel_metier_cle_en_main', bodacc)

      get demarche_path('marches-publics')

      expect(onglet_solutions.find('.solution-integratrice-card', visible: :all).text(:all)).to include("Donnée utile du cas d'usage intégrée")
    end

    it 'désactive l’onglet des solutions et le retire du sommaire quand aucune n’a intégré de donnée utile' do
      recommande(Solution.create!(nom: 'API BODACC', categorie: 'api'))

      get demarche_path('marches-publics')

      expect(page).to have_css('[role=tab][aria-controls=solutions-integratrices][disabled]', text: 'Solutions ayant intégré ces données (0)')
      expect(page).to have_no_css('nav.fr-summary a[href="#solutions-integratrices"]')
      expect(page).to have_css('nav.fr-summary a[href="#donnees-disponibles"]', text: 'Données disponibles et utiles')
    end
  end

  describe 'accès direct à la donnée recommandée' do
    it 'ne renvoie pas vers une fiche retirée du site' do
      demarche = Demarche.create!(nom: 'Démarches proactives', slug: 'demarches-proactives', visible: true)
      retiree = Solution.create!(nom: 'Bouquet retiré', categorie: 'brique_logicielle', slug: 'bouquet-retire', visible: false,
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      Recommandation.create!(demarche:, solution: retiree, niveau: :niveau_2, visible: true)

      get demarche_path('demarches-proactives')

      expect(response.body).not_to include('Plus d&#39;informations sur')
    end

    it 'montre la carte data.gouv du jeu de données même sans lien de demande d’accès ni endpoint utile' do
      demarche = Demarche.create!(nom: 'Démarches proactives', slug: 'demarches-proactives', visible: true)
      extrait = Solution.create!(nom: 'Extrait des coordonnées des étudiants boursiers', categorie: 'base_de_donnees',
        uid_datagouv: 'extrait1')
      Recommandation.create!(demarche:, solution: extrait, niveau: :niveau_2, visible: true)

      get demarche_path('demarches-proactives')

      expect(response.body).to include('Par le jeu de données directement')
      expect(response.body).to include('https://www.data.gouv.fr/fr/datasets/extrait1')
      expect(response.body).to include('Voir le jeu de données sur Data.gouv.fr')
      expect(response.body.scan('Aucune solution référencée').size).to eq(3)
    end

    it 'grise l’accordéon quand la donnée n’est pas sur data.gouv' do
      demarche = Demarche.create!(nom: 'Démarches proactives', slug: 'demarches-proactives', visible: true)
      a_venir = Solution.create!(nom: 'Nombre d’étudiants boursiers par territoire', categorie: 'base_de_donnees')
      Recommandation.create!(demarche:, solution: a_venir, niveau: :niveau_2, visible: true)

      get demarche_path('demarches-proactives')

      expect(response.body.scan('Aucune solution référencée').size).to eq(4)
    end
  end

  describe 'ordre des recommandations' do
    it 'suit l’ordre importé de Grist, pas celui des ids' do
      demarche = Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true)
      bio = Solution.create!(nom: 'API professionnels BIO', categorie: 'api')
      bodacc = Solution.create!(nom: 'API BODACC', categorie: 'api')
      Recommandation.create!(demarche:, solution: bio, niveau: :niveau_2, visible: true, ordre: 2)
      Recommandation.create!(demarche:, solution: bodacc, niveau: :niveau_2, visible: true, ordre: 1)

      get demarche_path('marches-publics')

      expect(response.body.index('Via «')).to be < response.body.index('API BODACC')
      expect(response.body.index('API BODACC')).to be < response.body.index('API professionnels BIO')
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
