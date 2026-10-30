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

    it 'propose une nouvelle démarche, avec la doctrine de référencement' do
      get demarches_path

      titre = response.parsed_body.at_css('#titre-proposer-demarche')
      expect(titre.at_css('[aria-hidden=true]').text).to eq('✒️')
      expect(lu_a_voix_haute(titre)).to eq('Proposer une nouvelle démarche')
      expect(response.parsed_body.text).to include('Doctrine de référencement des démarches')
      expect(response.body).to include('href="/contact/nouveau-cas-usage"')
      expect(response.parsed_body.css('main a[href="/#redaction-contenu"]')).to be_empty
      expect(response.body).to include('href="/doctrine-referencement-cas-usages"')
      expect(response.parsed_body.css('a.bouton-proposer-modification')).to be_empty
    end

    it 'rend chaque carte comme le site : titre, chapo, usagers et acteurs triés' do
      Demarche.create!(nom: 'Cantine à 1€', icone: '🥣', slug: 'cantine', visible: true,
        description_courte: "Communes, simplifiez.\nDeuxième ligne ignorée.",
        vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')],
        types_acteurs: [TypeActeur.create!(nom: 'Départements'), TypeActeur.create!(nom: 'Communes')])

      get demarches_path(q: 'cantine')

      lien = response.parsed_body.at_css('.demarche-card h3 a')
      expect(lien.at_css('[aria-hidden=true]').text).to eq('🥣')
      expect(lu_a_voix_haute(lien)).to eq('Cantine à 1€')
      expect(response.body).to include('Communes, simplifiez.')
      expect(response.body).not_to include('Deuxième ligne')
      expect(response.body).to include('Pour simplifier les démarches des <b>Particuliers</b>')
      expect(response.body).to include('fr-text--right')
      expect(response.body).to include('À destination des <b>Communes</b> et <b>Départements</b>')
    end

    it 'propose les facettes préremplies, appliquées par un bouton, et le passage aux solutions' do
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
      expect(response.body).not_to include('form#submit')
      expect(response.parsed_body.at_css('form.catalogue input[type=submit]')['value']).to eq('Appliquer les filtres')
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

    it 'garde « Aucun contenu actuellement » sans bouton « Lire plus » quand Contexte et Cadre juridique sont vides' do
      Demarche.create!(nom: 'Vide', slug: 'vide', visible: true)

      get demarche_path('vide')

      expect(response.body.scan('Aucun contenu actuellement').size).to eq(2)
      expect(response.body).not_to include('Lire plus')
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
        url_demande_acces: 'https://datapass.api.gouv.fr/api-particulier', types_solution: ['API'],
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

    it 'prépare pour Matomo l’ouverture de l’accès direct, l’étiquette API et les sorties vers data.gouv' do
      page = Capybara.string(response.body)

      acces_direct = page.find_button("Par l'API directement")
      expect(acces_direct['data-matomo-action']).to eq('Ouverture accès direct API-jdd')
      expect(acces_direct['data-matomo-nom']).to eq('Bouquet API Particulier [API, restreint public]')
      etiquette = page.find_button('API et jeux de données')
      expect(etiquette['data-matomo-action']).to eq('Affichage personnalisé API-jdd')
      expect(etiquette['data-matomo-nom']).to eq(Demarche.find_by(slug: 'tarification-cantine-scolaire-a-1eur').titre)
      expect(page.find_button('Sites de consultation des données')['data-matomo-action']).to be_nil
      expect(page.find_link('Bouquet API Particulier (data.gouv)')['data-matomo-nom'])
        .to eq('Bouquet API Particulier (data.gouv) [API, restreint public, démarche, carte]')
      sorties = page.all('a[data-matomo-nom^="API Quotient familial [API, démarche"]').pluck('data-matomo-nom')
      expect(sorties).to include('API Quotient familial [API, démarche, documentation]',
        'API Quotient familial [API, démarche, tableau]')
      expect(page.find_link('Documentation', match: :first)['data-matomo-action']).to eq('Sortie fiche data.gouv accès restreint')
    end

    it 'prépare pour Matomo l’ouverture des fiches solution de type API seulement' do
      page = Capybara.string(response.body)

      fiche = page.find_link('Plus d\'informations sur Bouquet API Particulier')
      expect(fiche['data-matomo-action']).to eq('Ouverture fiche solution API-jdd')
      expect(fiche['data-matomo-nom']).to eq('Bouquet API Particulier [API, restreint public, démarche]')
      expect(page.find_link('Voir la fiche Acheteza', match: :first)['data-matomo-action']).to be_nil
    end

    it 'donne à la recherche d’endpoints le nom de la solution pour Matomo' do
      tableau = Capybara.string(response.body).find('[data-controller="endpoints"]')

      expect(tableau['data-endpoints-solution-value']).to eq('Bouquet API Particulier')
    end

    it 'montre l’icône du titre sans la faire lire : titre de la page, h1 et fil d’Ariane' do
      titre = 'Cas d\'usage - Tarification cantine scolaire à 1€ | Simplifions.data.gouv.fr'
      expect(response.parsed_body.at_css('title').text).to eq(titre)
      expect(response.parsed_body.at_css('meta[property="og:title"]')['content']).to eq(titre)
      [response.parsed_body.at_css('h1'), response.parsed_body.at_css('.fr-breadcrumb [aria-current=page]')].each do |noeud|
        expect(noeud.at_css('[aria-hidden=true]').text).to eq('🥣')
        expect(lu_a_voix_haute(noeud)).to eq('Tarification cantine scolaire à 1€')
      end
    end

    it 'garde à l’écran les icônes ✍️ 💡 ✒️ et celle du titre, sans les lire à voix haute' do
      site = Solution.create!(nom: 'Portail agents', categorie: 'site_de_consultation', visible: true, slug: 'portail-agents')
      Integration.create!(integratrice: site, integree: Solution.find_by!(nom: 'API Quotient familial'), type_integration: 'consomme',
        statut: '✅ en production', demarches: [Demarche.find_by!(slug: 'tarification-cantine-scolaire-a-1eur')])

      get demarche_path('tarification-cantine-scolaire-a-1eur')

      icones = %w[🥣 ✍️ 💡 ✒️]
      vu = response.parsed_body.text
      lu = lu_a_voix_haute(response.parsed_body.at_css('body'))
      expect(icones.select { vu.include?(it) }).to eq(icones)
      expect(icones.select { lu.include?(it) }).to be_empty
    end

    it 'rend l’en-tête et la sidebar' do
      expect(response.body).to include('🥣')
      expect(response.body).to include('Communes, simplifiez la mise en œuvre du dispositif.')
      expect(response.body).to include('Particuliers')
      expect(response.body).to include('Communes et groupements de communes')
      expect(response.body).to include('Direction interministérielle du numérique')
      expect(response.body).to include('href="/contact/modifier-cas-usage?demarche=tarification-cantine-scolaire-a-1eur"')
      expect(response.body).to include('href="/#redaction-contenu"')
      expect(response.parsed_body.text).to include('proposer vos modifications de cette démarche')
      expect(response.body).not_to include('demarches-simplifiees.fr')
    end

    it 'fait sauter les liens du sommaire dans la page, sans visite Turbo qui la recharge' do
      liens = response.parsed_body.css('nav.fr-summary a[href^="#"]')

      expect(liens).not_to be_empty
      expect(liens).to all(satisfy { it.ancestors('[data-turbo="false"]').any? })
    end

    it 'garde un bouton « Proposer une modification » toujours visible, sans liens éparpillés' do
      bouton = response.parsed_body.at_css('a.bouton-proposer-modification')
      expect(bouton['target']).to eq('_blank')
      expect(bouton.at_css('.fr-hidden.fr-unhidden-sm').text).to eq('Proposer une modification')
      expect(bouton.at_css('.fr-hidden-sm').text).to eq('Une modification ?')
      expect(bouton.at_css('.fr-sr-only').text).to eq(' - nouvelle fenêtre')
      expect(response.parsed_body.at_css("##{bouton['aria-describedby']}[role=tooltip]").text)
        .to eq('Le contenu de Simplifions.data est collaboratif, si vous avez repéré une erreur ou un manque, écrivez-nous.')
      expect(bouton['href']).to eq('/contact/modifier-cas-usage?demarche=tarification-cantine-scolaire-a-1eur')
      expect(response.parsed_body.css('a[href="#modification-contenu"]')).to be_empty
    end

    it 'rend les sections contexte et cadre juridique en markdown' do
      expect(response.body).to include('<strong>progressive</strong>')
      expect(response.body).to include('href="https://legifrance.gouv.fr/codes/article_lc/LEGIARTI000039036672"')
    end

    it 'prépare Contexte à être replié derrière « Lire plus », texte entier sans JavaScript' do
      page = Capybara.string(response.body)

      expect(page).to have_css('#contexte-texte', text: 'progressive')
      expect(page).to have_no_css('#contexte-texte.lire-plus--replie')
      expect(page).to have_css("button.fr-link.fr-icon-arrow-down-s-line.fr-hidden[aria-expanded='false'][aria-controls='contexte-texte']",
        text: 'Lire plus')
    end

    it 'prépare Cadre juridique à être replié derrière « Lire plus », texte entier sans JavaScript' do
      page = Capybara.string(response.body)

      expect(page).to have_css('#cadre-juridique-texte', text: 'R.531-52')
      expect(page).to have_no_css('#cadre-juridique-texte.lire-plus--replie')
      expect(page).to have_css("button.fr-link.fr-icon-arrow-down-s-line.fr-hidden[aria-expanded='false'][aria-controls='cadre-juridique-texte']",
        text: 'Lire plus')
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
      expect(carte).to have_text('API « Bouquet API Particulier »')
      expect(carte[:class]).not_to include('fr-enlarge-link')
    end

    it 'propose « Plus d’informations » vers la fiche de la solution recommandée, avant la demande d’accès' do
      expect(Capybara.string(response.body)).to have_css('a.fr-btn.fr-btn--secondary[href="/solutions/bouquet-api-particulier"]',
        text: "Plus d'informations sur Bouquet API Particulier")
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

    it 'réserve au filtre des endpoints une annonce vide au chargement, pour le lecteur d’écran' do
      annonce = response.parsed_body.at_css('[data-controller=endpoints] [role=status]')
      expect(annonce.text).to be_empty
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
      expect(carte).to have_text('API intégrée')
      expect(carte).to have_no_text('1/1 API « Bouquet API Entreprise »')
    end
  end

  describe 'fenêtre des données intégrées ouverte depuis une carte' do
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
      inclusion = Solution.create!(nom: 'API Marché de l’inclusion', categorie: 'api')
      Recommandation.create!(demarche:, solution: inclusion, niveau: :niveau_2, visible: true, ordre: 4)

      get demarche_path('marches-publics')
    end

    let(:page) { Capybara.string(response.body) }

    def oeil(recommandee)
      page.find('.reco-card', text: /Via «\s+#{recommandee}\s+»/).find('button', text: 'Voir les données intégrées par Acheteza')
    end

    def fenetre(recommandee) = page.find("dialog.fr-modal##{oeil(recommandee)['aria-controls']}", visible: :all)
    def texte(recommandee) = fenetre(recommandee).text(:all).squish

    it 'ouvre une fenêtre par carte' do
      fenetres = ['Bouquet API Entreprise', 'Bouquet API Particulier', 'API Sirene'].map { fenetre(it)[:id] }

      expect(fenetres.uniq.size).to eq(3)
      expect(page).to have_css('dialog.fr-modal', count: 4, visible: :all)
    end

    it 'reprend le haut de la carte : compteur de la recommandation puis total du cas d’usage' do
      expect(fenetre('Bouquet API Entreprise')).to have_css('h2', text: 'Acheteza', visible: :all)
      expect(texte('Bouquet API Entreprise')).to include('Solution privée | Éditeur SAS')
        .and include('1/2 API « Bouquet API Entreprise » intégrées par cette solution, utiles pour la démarche « Marchés publics »')
        .and include('Sur l’ensemble du cas d’usage : 3/5 API et jeux de données utiles intégrés.')
    end

    it 'reprend la coche d’une carte à une seule donnée utile, puis le total' do
      expect(fenetre('Bouquet API Particulier')).to have_css('.indicator--green.fr-icon-check-line', visible: :all)
      expect(texte('Bouquet API Particulier')).to include('« Bouquet API Particulier » est intégrée par cette solution')
        .and include('Sur l’ensemble du cas d’usage : 3/5')
      expect(texte('Bouquet API Particulier')).not_to include('1/1 API')
    end

    it 'compte une API recommandée seule pour une donnée utile, cochée sur sa carte' do
      carte = oeil('API Sirene').ancestor('.solution-integratrice-card')

      expect(carte).to have_css('.indicator--green.fr-icon-check-line')
      expect(carte).to have_text('API intégrée')
      expect(texte('API Sirene')).to include('« API Sirene » est intégrée par cette solution')
    end

    it 'groupe les données par bouquet, les API seules ensemble, chaque groupe avec son compte' do
      expect(texte('Bouquet API Entreprise')).to include('Bouquet API Entreprise (1/2)')
        .and include('Bouquet API Particulier (1/1)')
        .and include('Autres API et jeux de données (1/2)')
      expect(texte('Bouquet API Entreprise')).to include('API Sirene : intégrée').and include('API Marché de l’inclusion : non intégrée')
    end

    it 'montre en tête d’un groupe le même compte que la carte de sa donnée recommandée' do
      carte = oeil('Bouquet API Entreprise').ancestor('.solution-integratrice-card')
      compte = carte.find('.solution-integratrice-card__couverture > .integration-indicator__count').text

      expect(texte('Bouquet API Entreprise')).to include("Bouquet API Entreprise (#{compte})")
    end

    it 'compte au total les coches sur les lignes' do
      lignes = fenetre('Bouquet API Entreprise').all('li', visible: :all).map { it.text(:all) }

      expect(lignes.size).to eq(5)
      expect(lignes.count { it.include?(': intégrée') }).to eq(3)
    end

    it 'coche chaque donnée utile intégrée, avec son détail data.gouv, sans la donnée qui attend sa publication' do
      fenetre = fenetre('Bouquet API Entreprise')

      expect(texte('Bouquet API Entreprise')).to include('API BODACC : intégrée')
        .and include('API professionnels BIO : non intégrée')
        .and include('API Quotient familial : intégrée')
      expect(fenetre.find('li', text: 'API BODACC', visible: :all).text(:all)).to include('API ouverte').and include('DILA')
      expect(fenetre).to have_link('Voir sur data.gouv.fr API BODACC - nouvelle fenêtre', href: 'https://www.data.gouv.fr/fr/dataservices/bodacc1', visible: :all)
      expect(response.body).not_to include('API pas encore publiée')
    end

    it 'prépare pour Matomo la sortie vers data.gouv depuis la fenêtre, avec son accès et son origine' do
      lien = fenetre('Bouquet API Entreprise').find_link('Voir sur data.gouv.fr API BODACC - nouvelle fenêtre', visible: :all)

      expect(lien['data-matomo-action']).to eq('Sortie fiche data.gouv accès ouvert')
      expect(lien['data-matomo-nom']).to eq('API BODACC [API, ouvert, démarche, modale liste api par solution]')
    end

    it 'replie le détail d’une donnée derrière sa ligne, qui s’ouvre et se referme au clic' do
      ligne = fenetre('Bouquet API Entreprise').find('li', text: 'API BODACC', visible: :all)
      bascule = ligne.find('details > summary', visible: :all).text(:all).squish

      expect(bascule).to eq('API BODACC : intégrée')
      expect(ligne.text(:all)).to include('API ouverte').and include('Producteur : DILA').and include('Voir sur data.gouv.fr')
    end

    it 'montre sur la carte le compte de sa recommandation et le total, comme sa fenêtre' do
      carte = oeil('Bouquet API Entreprise').ancestor('.solution-integratrice-card').text.squish

      expect(carte).to include('1/2 API « Bouquet API Entreprise »')
        .and include('3/5 API ou jeux de données au total pour ce cas d’usage')
    end
  end

  describe 'bouquet recommandé qui n’expose aucune API' do
    it 'n’a pas de compteur sur ses cartes et sort du total du cas d’usage' do
      demarche = Demarche.create!(nom: 'Authentification d’un particulier', slug: 'authentification-particulier', visible: true)
      etat = Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')
      franceconnect = Solution.create!(nom: 'FranceConnect', categorie: 'brique_logicielle', organisations: [etat])
      nc_connect = Solution.create!(nom: 'NC Connect', categorie: 'brique_logicielle', organisations: [etat])
      api_franceconnect = Solution.create!(nom: 'API FranceConnect', categorie: 'api')
      Integration.create!(integratrice: franceconnect, integree: api_franceconnect, type_integration: 'expose')
      Recommandation.create!(demarche:, solution: franceconnect, niveau: :niveau_2, visible: true, ordre: 1)
      Recommandation.create!(demarche:, solution: nc_connect, niveau: :niveau_2, visible: true, ordre: 2)
      Recommandation.create!(demarche:, solution: api_franceconnect, niveau: :niveau_1, visible: true)
      civil = Solution.create!(nom: 'CIVIL Enfance', slug: 'civil-enfance', categorie: 'logiciel_metier_cle_en_main', visible: true)
      [api_franceconnect, nc_connect].each do |integree|
        Integration.create!(integratrice: civil, integree:, type_integration: 'consomme', statut: '✅ en production', demarches: [demarche])
      end

      get demarche_path('authentification-particulier')

      page = Capybara.string(response.body)
      carte_nc_connect = page.find('.reco-card', text: /Via «\s+NC Connect\s+»/).find('.solution-integratrice-card')
      expect(carte_nc_connect).to have_no_css('.solution-integratrice-card__couverture > .integration-indicator__count')
      expect(carte_nc_connect.text.squish).to include('1/1 API ou jeux de données au total pour ce cas d’usage')
      fenetres = page.all('dialog.fr-modal', visible: :all).map { it.text(:all).squish }.join
      expect(fenetres).to include('API FranceConnect : intégrée')
      expect(fenetres).not_to include('NC Connect : non intégrée')
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

      it 'range les solutions par catégorie, les plus intégrées d’abord' do
        expect(onglet_solutions.all('h3 > button .section-depliable__titre', visible: :all).map { it.text(:all).squish })
          .to eq(['Logiciels métier « clé en main »', 'Briques logicielles à intégrer'])
        expect(onglet_solutions.all('.solution-integratrice-card__title', visible: :all).map { it.text(:all).squish })
          .to eq(['Zeta', 'Acheteza', 'Brique marchés'])
      end

      it 'titre chaque catégorie d’un bouton fléché qui la déplie, hors accordéon du DSFR, dépliée sans JavaScript' do
        titre = onglet_solutions.first('h3', visible: :all)
        bouton = titre.find('button[aria-expanded=true]', visible: :all)

        expect(titre.all(:xpath, './*', visible: :all).size).to eq(1)
        expect(bouton.first('span', visible: :all)[:class]).to include('fr-icon-arrow-down-s-fill')
        expect(onglet_solutions).to have_css("##{bouton[:'aria-controls']}:not([hidden]) .solution-integratrice-card", visible: :all)
        expect(onglet_solutions).to have_no_css('.fr-accordion, .fr-collapse', visible: :all)
        expect(onglet_solutions[:class]).to include('fr-background-alt--blue-france')
      end

      it 'badge le titre de chaque catégorie de son nombre de solutions, « Sans développement » hors briques' do
        expect(onglet_solutions.all('h3 > button', visible: :all).map { it.all('.fr-badge', visible: :all).map { it.text(:all).squish } })
          .to eq([['2 logiciels', 'Sans développement'], ['1 brique']])
      end

      it 'présente chaque catégorie d’une phrase, repliée avec elle' do
        phrases = %w[logiciel-metier-cle-en-main brique-logicielle].map do |categorie|
          onglet_solutions.find("#solutions-integratrices-#{categorie} > p:first-child", visible: :all).text(:all).squish
        end

        expect(phrases).to eq([
          "Logiciels métier, sur étagère, conçus pour ce cas d'usage.",
          "Briques techniques logicielles destinées à être intégrées dans un système informatique existant et conçues pour ce cas d'usage."
        ])
      end

      it 'compte sur chaque carte le total du cas d’usage, et son œil ouvre la fenêtre de la solution' do
        carte = onglet_solutions.find('.solution-integratrice-card', text: 'Acheteza', visible: :all)
        fenetre = page.find("dialog.fr-modal##{carte.find('button', text: 'Voir les données intégrées par Acheteza', visible: :all)['aria-controls']}", visible: :all)

        expect(carte.text(:all).squish).to include('1/3 API ou jeux de données au total pour ce cas d’usage')
        expect(carte.text(:all)).not_to include('«')
        expect(fenetre.text(:all).squish).to include('Sur l’ensemble du cas d’usage : 1/3').and include('API BODACC : intégrée')
      end

      it 'propose d’afficher les solutions en cartes, choisies d’office, ou en tableau comparatif' do
        choix = onglet_solutions.find('fieldset', text: 'Affichage des solutions', visible: :all)

        expect(choix).to have_field('Cartes', type: 'radio', checked: true, visible: :all)
        expect(choix).to have_field('Tableau comparatif', type: 'radio', checked: false, visible: :all)
        expect(onglet_solutions.text(:all)).not_to include('Les solutions sont classées')
      end

      it 'compare par catégorie, colonnes groupées par bouquet, les données intégrées par chaque solution' do
        tableaux = onglet_solutions.all('table', visible: :all)
        lignes = tableaux.map do |tableau|
          tableau.all('tbody tr', visible: :all).map { |ligne| ligne.all('th, td', visible: :all).map { it.text(:all).squish } }
        end

        expect(tableaux.map { it.find('caption', visible: :all).text(:all).squish }).to eq([
          'API et jeux de données utiles intégrés par chaque solution : Logiciels métier « clé en main »',
          'API et jeux de données utiles intégrés par chaque solution : Briques logicielles à intégrer'
        ])
        expect(tableaux.first.all('thead th[scope=colgroup]', visible: :all).map { it.text(:all).squish })
          .to eq(['Bouquet API Entreprise', 'Autres API et jeux de données'])
        expect(tableaux.first.all('thead th[scope=col]', visible: :all).map { it.text(:all).squish })
          .to eq(['Solution', 'Données intégrées pour ce cas d’usage', 'API BODACC', 'API professionnels BIO', 'API Sirene'])
        expect(lignes).to eq([
          [['Zeta', '2/3', 'Intégrée', 'Intégrée', 'Non intégrée'], ['Acheteza', '1/3', 'Intégrée', 'Non intégrée', 'Non intégrée']],
          [['Brique marchés', '1/3', 'Non intégrée', 'Intégrée', 'Non intégrée']]
        ])
      end

      it 'annonce chaque case du tableau avec sa solution et sa donnée' do
        tableau = onglet_solutions.first('table', visible: :all)
        case_acheteza_bio = tableau.find('tbody tr', text: 'Acheteza', visible: :all).all('td', visible: :all)[2]
        annonce = case_acheteza_bio['headers'].split.map { tableau.find("##{it}", visible: :all).text(:all).squish }

        expect(annonce + [case_acheteza_bio.text(:all).squish])
          .to eq(['Acheteza', 'Bouquet API Entreprise', 'API professionnels BIO', 'Non intégrée'])
      end

      it 'propose avec le fil d’Ariane les trois tags de l’affichage personnalisé, aucun choisi' do
        entete = page.find('.affichage-personnalise__entete')
        tags = entete.all('button.fr-tag[aria-pressed]')

        expect(entete).to have_css('nav.fr-breadcrumb')
        expect(entete).to have_text('Affichez le contenu de cette page selon les solutions que vous recherchez :')
        expect(tags.map { [it.text.squish, it[:'aria-pressed']] }).to eq([
          ['API et jeux de données', 'false'], ['Logiciels métiers « clé en main »', 'false'], ['Sites de consultation des données', 'false']
        ])
      end

      it 'rouvre les tags sous le fil d’Ariane par le bouton « Affichage personnalisé », caché sans JavaScript' do
        bouton = page.find('.affichage-personnalise__entete button', text: 'Affichage personnalisé', visible: :all)

        expect(bouton[:class]).to include('fr-hidden')
        expect(page.find("##{bouton[:'aria-controls']}.fr-collapse", visible: :all)).to have_css('button.fr-tag', count: 3, visible: :all)
      end

      it 'rattache chaque section des deux onglets à un tag, repliée dans le premier, dépliée dans le second' do
        section = ->(bloc) { [bloc[:'data-filtre'], bloc.find('.section-depliable__titre, h5', visible: :all).text(:all).squish] }
        reco = page.find('#donnees-disponibles .reco-card', text: 'Bouquet API Entreprise')

        expect(reco.all('[data-filtre]', visible: :all).map(&section)).to match([
          ['api', "Par l'API directement"], ['api', start_with('Via une brique logicielle')],
          ['logiciels', start_with('Via un logiciel métier')], ['sites', start_with('Via un site de consultation')]
        ])
        expect(onglet_solutions.all('[data-filtre]', visible: :all).map(&section))
          .to eq([['logiciels', 'Logiciels métier « clé en main »'], ['api', 'Briques logicielles à intégrer']])
        expect(page.all('#donnees-disponibles button.fr-accordion__btn', visible: :all).pluck(:'aria-expanded').uniq).to eq(['false'])
        expect(onglet_solutions.all('h3 > button', visible: :all).pluck(:'aria-expanded').uniq).to eq(['true'])
      end

      it 'propose de trier par données intégrées, choisi d’office, ou par titre, cartes et tableaux ensemble' do
        tri = onglet_solutions.find_field('Trier par :', visible: :all)
        ordre_servi = ->(liste) { liste.all('[data-nom]', visible: :all).map { [it['data-nom'], it['data-ordre']] } }

        expect(tri.all('option', visible: :all).map { [it.text(:all), it.selected?] })
          .to eq([['Le plus de données intégrées', true], ['Titre', false]])
        expect(onglet_solutions.all('[data-tri-solutions-target=liste]', visible: :all).map(&ordre_servi)).to eq([
          [%w[Zeta 0], %w[Acheteza 1]], [%w[Zeta 0], %w[Acheteza 1]], [['Brique marchés', '0']], [['Brique marchés', '0']]
        ])
        expect(onglet_solutions).to have_no_button(text: /Trier par/, visible: :all)
      end

      it 'rend les fenêtres hors des onglets' do
        expect(page).to have_no_css('[role=tabpanel] dialog', visible: :all)
      end
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

  describe 'libellés des moyens d’accès' do
    it 'nomme chaque accordéon par catégorie, avec son compte ou son absence' do
      demarche = Demarche.create!(nom: 'Cantine', slug: 'cantine', visible: true)
      api_qf = Solution.create!(nom: 'API Quotient familial', categorie: 'api')
      Recommandation.create!(demarche:, solution: api_qf, niveau: :niveau_2, visible: true)
      [%w[Alpha brique_logicielle], %w[Beta brique_logicielle], %w[Acheteza logiciel_metier_cle_en_main]].each do |nom, categorie|
        integratrice = Solution.create!(nom:, slug: nom.downcase, categorie:, visible: true)
        Integration.create!(integratrice:, integree: api_qf, type_integration: 'consomme', statut: '✅ en production', demarches: [demarche])
      end

      get demarche_path('cantine')

      expect(response.parsed_body.css('#donnees-disponibles .fr-accordion__title').map { it.text.squish }.drop(1)).to eq([
        'Via une brique logicielle à intégrer 2 briques',
        'Via un logiciel métier « clé en main » 1 logiciel Sans développement',
        'Via un site de consultation Aucun site (Aucune solution référencée)'
      ])
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
