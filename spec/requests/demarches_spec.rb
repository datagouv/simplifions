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

    it 'replie le contexte et le cadre juridique derrière un bouton « Lire plus » chacun' do
      boutons = response.parsed_body.at_css('#contexte-et-cadre-juridique').parent.css('button[aria-expanded="false"]')
      expect(boutons.map { |bouton| bouton.text.squish }).to eq(['Lire plus', 'Lire plus'])
      textes = boutons.map { |bouton| response.parsed_body.at_css("##{bouton['aria-controls']}").text.squish }
      expect(textes).to eq(['Une grille tarifaire progressive est requise.', 'Voir R.531-52.'])
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

    it 'rend chaque intégratrice comme le site : titre en gras, types de solution, données utiles intégrées toutes démarches confondues' do
      expect(response.body).to match(%r{<p class="[^"]*fr-text--bold[^"]*">\s*<a[^>]*>Acheteza</a>})
      expect(response.body).to include('Profil acheteur • Portail agent')
      carte = response.parsed_body.at_css('#donnees-disponibles .solution-integratrice-card')
      expect(carte['class']).not_to include('fr-enlarge-link')
      expect(carte.at_css('a.fr-link[href="/solutions/acheteza"]').text.squish).to eq('Voir la fiche Acheteza')
      expect(carte.at_css('.integration-indicator').text.squish)
        .to eq('2/2 API ou jeu de données utiles Bouquet API Particulier Voir les données intégrées par Acheteza')
      bouton = carte.at_css('button.fr-icon-eye-line')
      expect(bouton['title']).to eq('Voir les données intégrées par Acheteza')
      modale = response.parsed_body.at_css("dialog##{bouton['aria-controls']}")
      expect(modale.at_css('.fr-modal__title a[href="/solutions/acheteza"]').text).to eq('Acheteza')
      expect(modale.at_css('.integration-indicator').text.squish)
        .to eq('2/2 API et jeux de données utiles pour la démarche « 🥣 Tarification cantine scolaire à 1€ » intégrés par cette solution')
      expect(modale.css('.integration-indicator b').map(&:text))
        .to eq(['API et jeux de données utiles pour la démarche', 'intégrés par cette solution'])
      expect(modale.css('li').map { |ligne| ligne.text.squish })
        .to eq(['API Quotient familial : intégrée Voir sur data.gouv.fr', 'API Statut étudiant : intégrée'])
      expect(modale.ancestors('.fr-tabs')).to be_empty
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

  describe 'solutions ayant intégré des données' do
    let(:demarche) { Demarche.create!(nom: 'Marchés publics', slug: 'marches-publics', visible: true) }

    before do
      bouquet = Solution.create!(nom: 'API Entreprise', categorie: 'brique_logicielle', organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])
      Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true)
      %w[Kbis Urssaf].each do |nom|
        endpoint = Solution.create!(nom:, categorie: 'api')
        Integration.create!(integratrice: bouquet, integree: endpoint, type_integration: 'expose')
        Recommandation.create!(demarche:, solution: endpoint, niveau: :niveau_1)
      end
    end

    def integre(nom, categorie, donnees)
      integratrice = Solution.create!(nom:, slug: nom.parameterize, categorie:, visible: true)
      Solution.where(nom: donnees).find_each do |integree|
        Integration.create!(integratrice:, integree:, type_integration: 'consomme', statut: '✅ en production', demarches: [demarche])
      end
    end

    def noms_des_cartes
      response.parsed_body.css('#solutions-integratrices .solution-integratrice-card').map { |carte| carte.at_css('a').text }
    end

    it 'liste les logiciels métier du plus intégré au moins intégré, filtrables par catégorie' do
      integre('Zeta achats', 'logiciel_metier_cle_en_main', %w[Kbis Urssaf])
      integre('Alpha achats', 'logiciel_metier_cle_en_main', %w[Kbis])
      integre('Annuaire', 'site_de_consultation', %w[Urssaf])

      get demarche_path('marches-publics')

      section = response.parsed_body.at_css('#solutions-integratrices')
      expect(section.css('button.fr-tag[aria-pressed="true"]').map { |tag| tag.text.squish })
        .to eq(['Logiciels métier « clé en main » (2)', 'Sites de consultation (1)'])
      expect(noms_des_cartes).to eq(['Zeta achats', 'Alpha achats', 'Annuaire'])
      cartes = section.css('.solution-integratrice-card')
      expect(cartes.map { |carte| carte.at_css('.integration-indicator__count').text }).to eq(%w[2/2 1/2 1/2])
      expect(cartes.first.at_css('.integration-indicator').text.squish)
        .to eq('2/2 API et jeux de données utiles Voir les données intégrées par Zeta achats')
      alpha = response.parsed_body.at_css("dialog##{cartes[1].at_css('button.fr-icon-eye-line')['aria-controls']}")
      expect(alpha.at_css('details[open] > summary h3').text.squish).to eq('API Entreprise (1/2)')
      expect(alpha.css('li').map { |ligne| ligne.text.squish }).to eq(['Kbis : intégrée', 'Urssaf : non intégrée'])
    end

    it 'propose de trier les solutions par données intégrées ou par titre' do
      integre('Zeta achats', 'logiciel_metier_cle_en_main', %w[Kbis Urssaf])
      integre('Alpha achats', 'logiciel_metier_cle_en_main', %w[Kbis])

      get demarche_path('marches-publics')

      section = response.parsed_body.at_css('#solutions-integratrices')
      tri = section.at_css('select#tri-solutions-integratrices')
      expect(section.at_css('label[for="tri-solutions-integratrices"]').text).to eq('Trier par :')
      expect(tri.css('option').map(&:text)).to eq(['Le plus de données intégrées', 'Titre'])
      nom_et_ordre = ->(element) { [element['data-nom'], element['data-ordre']] }
      expect(section.css('.solution-integratrice-card').map { |carte| nom_et_ordre.call(carte.parent) })
        .to eq([['Zeta achats', '0'], ['Alpha achats', '1']])
      expect(section.css('tbody tr').map(&nom_et_ordre)).to eq([['Zeta achats', '0'], ['Alpha achats', '1']])
    end

    it 'présente dans le tableau l’accès et la fiche data.gouv de chaque donnée' do
      Solution.find_by(nom: 'Kbis').update!(uid_datagouv: 'kbis1', datagouv_organisation: 'Infogreffe', datagouv_acces: 'open')
      integre('Alpha achats', 'logiciel_metier_cle_en_main', %w[Kbis])

      get demarche_path('marches-publics')

      kbis, urssaf = response.parsed_body.css('#solutions-integratrices thead tr:last-child th')
      expect(kbis.at_css('.fr-badge').text.squish).to eq('API ouverte')
      expect(kbis.text).not_to include('Producteur')
      lien = kbis.at_css('a[target=_blank]')
      expect([lien['href'], lien.text.squish]).to eq(['https://www.data.gouv.fr/fr/dataservices/kbis1', 'Data.gouv.fr : Kbis'])
      expect(urssaf.text.squish).to eq('Urssaf')
    end

    it 'déplie chaque donnée de la modale vers sa fiche data.gouv, sans répéter le nom du bouquet' do
      Solution.find_by(nom: 'Kbis').update!(nom: 'Kbis | API Entreprise', uid_datagouv: 'kbis1', datagouv_organisation: 'Infogreffe',
        datagouv_acces: 'restricted', datagouv_acces_acteurs_publics: 'yes')
      integre('Alpha achats', 'logiciel_metier_cle_en_main', ['Kbis | API Entreprise'])

      get demarche_path('marches-publics')

      bouton = response.parsed_body.at_css('#solutions-integratrices button.fr-icon-eye-line')
      kbis, urssaf = response.parsed_body.css("dialog##{bouton['aria-controls']} li")
      expect(kbis.at_css('details:not([open]) > summary').text.squish).to eq('Kbis : intégrée')
      expect(kbis.at_css('details .fr-badge').text.squish).to eq('API restreinte · accessible aux acteurs publics')
      expect(kbis.at_css('details').text).to include('Producteur : Infogreffe')
      lien = kbis.at_css('details a')
      expect([lien['href'], lien.text.squish]).to eq(['https://www.data.gouv.fr/fr/dataservices/kbis1', 'Voir sur data.gouv.fr'])
      expect(urssaf.at_css('details')).to be_nil
      proposition = response.parsed_body.at_css("dialog##{bouton['aria-controls']} a[href*='proposer-un-contenu']")
      expect([proposition.text, proposition['target']]).to eq(['proposer une modification du contenu', '_blank'])
    end

    it 'filtre par catégorie et par solution publique, sans phrase d’introduction' do
      integre('Acheteza', 'logiciel_metier_cle_en_main', %w[Kbis])
      integre('Annuaire', 'site_de_consultation', %w[Kbis])
      Solution.find_by!(nom: 'Annuaire').organisations << Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')

      get demarche_path('marches-publics')

      section = response.parsed_body.at_css('#solutions-integratrices')
      expect(section.text).not_to include('Nombre d\'API et de jeux de données utiles')
      expect(section.text).to include('Filtrer les solutions', 'Par catégorie :')
      expect(section.at_css('label[for="filtre-solutions-publiques"]').text).to eq('Solutions publiques')
      expect(section.at_css('input#filtre-solutions-publiques.fr-toggle__input')['checked']).to be_nil
      expect(section.css('li[data-privee]').map { |carte| [carte.at_css('a').text, carte['data-privee']] })
        .to eq([%w[Acheteza true], %w[Annuaire false]])
    end

    it 'propose une vue tableau qui compare les données intégrées par chaque solution' do
      integre('Alpha achats', 'logiciel_metier_cle_en_main', %w[Kbis])
      integre('Annuaire', 'site_de_consultation', %w[Kbis Urssaf])
      Solution.find_by!(nom: 'Annuaire').update!(types_solution: ['Annuaire en ligne'],
        organisations: [Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public')])

      get demarche_path('marches-publics')

      section = response.parsed_body.at_css('#solutions-integratrices')
      expect(section.at_css('tbody tr th .fr-badge').text.squish).to eq('Public | DINUM')
      expect(section.at_css('tbody tr th .tableau-integratrices__detail').text).to eq('Annuaire en ligne')
      expect(section.css('.fr-segmented input, .fr-toggle__input').map { |champ| champ.attr('autocomplete') }).to all(eq('off'))
      expect(section.css('.fr-segmented input[type="radio"]').map { |choix| choix.attr('value') }).to eq(%w[cartes tableau])
      tableau = section.at_css('[data-categories-integratrices-target="tableau"]')
      expect(tableau['class']).to include('fr-hidden')
      expect(tableau.css('thead tr:first-child th').map { |entete| entete.text.squish })
        .to eq(['Solution', 'Données intégrées pour ce cas d\'usage', 'API Entreprise'])
      expect(tableau.css('thead tr:last-child th').map { |colonne| colonne.text.squish }).to eq(%w[Kbis Urssaf])
      lignes = tableau.css('tbody tr').map do |ligne|
        [ligne.at_css('th a').text, *ligne.css('td').map { |cellule| cellule.text.squish }]
      end
      expect(tableau.css('tbody tr').map { |ligne| ligne.attr('data-categorie') }).to eq(%w[site_de_consultation logiciel_metier_cle_en_main])
      expect(lignes).to eq([
        ['Annuaire', '2/2', 'Intégrée', 'Intégrée'],
        ['Alpha achats', '1/2', 'Intégrée', '– Non intégrée']
      ])
    end

    it 'enchaîne logiciels métier, briques puis sites, chacun avec sa description' do
      integre('Annuaire', 'site_de_consultation', %w[Kbis])
      integre('Passe Marché', 'brique_logicielle', %w[Kbis])
      integre('Acheteza', 'logiciel_metier_cle_en_main', %w[Kbis])

      get demarche_path('marches-publics')

      expect(noms_des_cartes).to eq(['Acheteza', 'Passe Marché', 'Annuaire'])
      categories = response.parsed_body.css('#solutions-integratrices div[data-categorie]')
      expect(categories.map { |categorie| [categorie.at_css('h3').text.squish, categorie.at_css('p').text.squish] }).to eq([
        ['Logiciels métier « clé en main » (1) Sans développement', 'Logiciels métier, sur étagère, conçus pour ce cas d\'usage.'],
        ['Briques logicielles à intégrer (1)',
         'Briques techniques logicielles destinées à être intégrées dans un système informatique existant et conçues pour ce cas d\'usage.'],
        ['Sites de consultation (1) Sans développement', 'Ces sites vous permettent de consulter certaines des données utiles pour ce cas d\'usage.']
      ])
    end

    it 'range données et solutions dans deux onglets, ouvrables depuis le sommaire' do
      integre('Acheteza', 'logiciel_metier_cle_en_main', %w[Kbis])

      get demarche_path('marches-publics')

      onglets = response.parsed_body.css('[role="tab"]')
      expect(onglets.map { |onglet| [onglet.text, onglet.attr('aria-controls'), onglet.attr('aria-selected')] })
        .to eq([['Données disponibles et utiles (1)', 'donnees-disponibles', 'true'],
                ['Solutions ayant intégré ces données (1)', 'solutions-integratrices', 'false']])
      expect(response.parsed_body.css('.fr-summary__link').map(&:text))
        .to eq(['Contexte et cadre juridique', 'Données disponibles et utiles', 'Solutions ayant intégré ces données'])
      expect(response.parsed_body.at_css('[data-controller="onglet-ancre"]')).to be_present
    end

    it 'ne propose que l’onglet des données quand aucune solution n’a intégré de données' do
      get demarche_path('marches-publics')

      expect(response.parsed_body.css('[role="tab"]').map(&:text)).to eq(['Données disponibles et utiles (1)'])
      expect(response.parsed_body.at_css('#solutions-integratrices')).to be_nil
      expect(response.body).not_to include('Solutions ayant intégré ces données')
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
