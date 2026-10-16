require 'rails_helper'

RSpec.describe 'Contact' do
  let(:email) { 'contact-simplifions@data.gouv.fr' }

  def titres_des_tuiles
    response.parsed_body.css('.fr-tile__title a').map { |lien| [lien['href'], lien.text.strip] }
  end

  describe 'GET /contact' do
    before { get contact_path }

    it 'propose les cinq besoins de la première étape, sans adresse' do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<h1>Nous contacter</h1>', 'Quel est votre besoin ?')
      expect(titres_des_tuiles).to eq([
        ['/contact/contenu', 'Proposer ou corriger un contenu du site'],
        ['/contact/demarche-personnelle', "J'ai une question sur ma propre démarche administrative"],
        ['/contact/question-api', "J'ai une question sur une API ou un jeu de données"],
        ['/contact/probleme-site', "Signaler un problème technique ou d'accessibilité sur le site"],
        ['/contact/autre', 'Autre sujet']
      ])
      expect(response.body).to include('Un dossier, une aide, un document à obtenir en tant que particulier, entreprise ou association.')
      expect(response.body).to match(%r{<use class="fr-artwork-major fr-artwork-major--blue-france" href="/assets/artwork/pictograms/digital/avatar-\h+\.svg#artwork-major">})
      expect(response.body).not_to include(email)
    end

    it 'reprend le pictogramme de chaque tuile à côté du titre de la page suivante' do
      tuiles = %w[/contact /contact/contenu].flat_map do |chemin|
        get chemin
        response.parsed_body.css('.fr-tile').map { |tuile| [tuile.at('a')['href'], tuile.at('use')['href']] }
      end

      tuiles.to_h.except('/contact/contenu').each do |lien, pictogramme|
        get lien
        expect(response.parsed_body.at('.contact-titre h2 + svg[aria-hidden="true"] use')['href']).to eq(pictogramme)
      end
    end

    it 'reste indexable' do
      expect(response.body).not_to include('<meta name="robots"')
    end
  end

  describe 'GET /contact/contenu' do
    before { get contact_path('contenu') }

    it 'précise la demande de contenu en sept besoins groupés, sans donner l’adresse' do
      expect(response.body).to include('Précisez votre demande')
      expect(titres_des_tuiles).to eq([
        ['/contact/modifier-cas-usage', "Proposer une modification d'une démarche existante"],
        ['/contact/nouveau-cas-usage', 'Proposer une nouvelle démarche'],
        ['/contact/modifier-solution', "Proposer une modification d'une fiche solution existante"],
        ['/contact/nouvelle-solution', 'Référencer une nouvelle solution'],
        ['/contact/modifier-article', "Proposer une modification d'un article existant"],
        ['/contact/nouvel-article', 'Proposer un nouvel article'],
        ['/contact/autre-contenu', "Proposer la modification d'un autre contenu"]
      ])
      expect(response.parsed_body.css('h3').map(&:text)).to eq(['Démarches', 'Solutions', 'Articles', 'Autre contenu'])
      expect(response.body).to include('title="Voir les démarches - nouvelle fenêtre"')
      expect(response.body).not_to include(email)
    end

    it 'revient à la première étape et n’est pas indexée' do
      expect(response.body).to include('href="/contact"')
      expect(response.body).to include('<meta name="robots" content="noindex">')
    end
  end

  describe 'étape finale' do
    before do
      TypeActeur.create!(nom: 'Communes et groupements de communes')
      TypeActeur.create!(nom: 'Caisses des écoles')
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      Vocabulaire.create!(nom: 'Associations', slug: 'associations', categorie: 'usager')
    end

    it 'donne les ressources à vérifier, l’adresse et un mail prérempli' do
      get contact_path('nouveau-cas-usage')

      expect(response.parsed_body.at('h2.fr-h3').text).to eq('Proposer une nouvelle démarche')
      expect(response.body).to include('Avant de nous écrire :', 'href="/doctrine-referencement-cas-usages"')
      expect(response.body).not_to include('Informations à nous transmettre')
      expect(response.parsed_body.at('#adresse-message').text).to eq(email)
      expect(response.parsed_body.at('#objet-message').text).to eq("Proposition d'une nouvelle démarche")
      expect(response.body).to include("href=\"mailto:#{email}?body=Bonjour%2C")
      expect(response.body).to include('&amp;subject=Proposition%20d%27une%20nouvelle%20d%C3%A9marche"')
      expect(response.body).to include(ERB::Util.html_escape(
        "Les types d'administrations concernées (gardez les mentions utiles) :\n- Communes et groupements de communes\n- Caisses des écoles"
      ))
      expect(response.body).to include(ERB::Util.html_escape(
        "Le public concerné (gardez les mentions utiles) :\n- Particuliers\n- Associations"
      ))
      expect(response.parsed_body.at('a[href^="mailto:"]').text).to eq('Ouvrir un e-mail déjà pré-rempli')
      expect(response.body).to include('href="/contact/contenu"')
      expect(response.parsed_body.css('input, textarea')).to be_empty
    end

    it 'présente le modèle prêt à l’emploi, puis les modèles à copier soi-même' do
      get contact_path('nouvel-article')

      texte = response.parsed_body.text
      expect(texte).to include("Utilisez le modèle d'e-mail ci-dessous pour nous transmettre les informations " \
                               'qui nous seront utiles pour comprendre votre proposition.')
      expect(texte).to include("l'adresse, l'objet et les rubriques du message déjà remplis")
      titres = response.parsed_body.css('h3').map(&:text)
      expect(titres).to include("Utiliser le mail prêt à l'emploi :", 'Copier/coller le modèle pour écrire vous-même le mail :')
      expect(titres).not_to include("Écrire à l'équipe :")
      expect(response.parsed_body.css('h4')).to be_empty
      expect(response.body.index('href="mailto:')).to be < response.body.index('Copier/coller le modèle')
    end

    it 'termine le modèle sur la dernière rubrique, sans formule de politesse' do
      get contact_path('nouvel-article')

      modele = response.parsed_body.at('#modele-message').text
      expect(modele).to start_with('Bonjour,')
      expect(modele).not_to include('Cordialement')
      expect(CGI.unescape(response.parsed_body.at('a[href^="mailto:"]')['href'])).not_to include('Cordialement')
    end

    it 'parle du problème rencontré, et non d’une proposition, sur le signalement d’un problème' do
      get contact_path('probleme-site')

      texte = response.parsed_body.text
      expect(texte).to include("Utilisez le modèle d'e-mail ci-dessous pour nous transmettre les informations " \
                               'qui nous seront utiles pour comprendre le problème que vous avez rencontré.')
      expect(texte).not_to include('comprendre votre proposition')
    end

    it 'parle du sujet, et non d’une proposition, sur la rubrique Autre sujet' do
      get contact_path('autre')

      texte = response.parsed_body.text
      expect(texte).to include("Utilisez le modèle d'e-mail ci-dessous pour nous transmettre les informations " \
                               'qui nous seront utiles pour comprendre votre sujet.')
      expect(texte).not_to include('comprendre votre proposition')
    end

    it 'propose de copier l’adresse, l’objet et le modèle, boutons cachés jusqu’au chargement du script' do
      get contact_path('autre')

      boutons = response.parsed_body.css('[data-controller="copier"] button[data-action="copier#copier"]')
      expect(boutons.map(&:text)).to eq(["Copier l'e-mail", "Copier l'objet", 'Copier le modèle'])
      expect(boutons).to all(satisfy { |bouton| bouton['class'].include?('fr-hidden') })
      expect(boutons.first['data-copier-texte-param']).to eq(email)
      expect(boutons[1]['data-copier-texte-param']).to eq('Prise de contact - autre sujet')
      expect(boutons.last['data-copier-texte-param']).to eq(response.parsed_body.at('#modele-message').text)
      expect(response.parsed_body.at('[aria-live="polite"][data-copier-target="statut"]')).to be_present
    end

    it 'garde chaque lien e-mail sous 2 000 caractères, les options restant dans le modèle à copier' do
      30.times { |rang| TypeActeur.create!(nom: "Établissements publics nationaux à caractère administratif #{rang}") }

      PagesController::BESOINS_DE_CONTACT.each do |besoin|
        get contact_path(besoin)
        lien = response.parsed_body.at('a[href^="mailto:"]')
        next unless lien

        expect(lien['href'].size).to be < 2000, besoin
      end

      get contact_path('nouvelle-solution')
      modele = response.parsed_body.at('#modele-message').text
      expect(modele).to include("Les types d'administrations concernées (gardez les mentions utiles) :\n- Communes et groupements de communes")
      expect(modele).to include('- Établissements publics nationaux à caractère administratif 29', '- Particuliers')
      lien = CGI.unescape(response.parsed_body.at('a[href^="mailto:"]')['href'])
      expect(lien).to include("Les types d'administrations concernées :")
      expect(lien).not_to include('- Particuliers')
    end

    it 'sépare les lignes du mail par CRLF dans le lien, comme le demande la RFC 6068' do
      get contact_path('autre')

      expect(response.body).to include('body=Bonjour%2C%0D%0A%0D%0A')
      expect(response.body).to include("Bonjour,\n\n")
    end

    {
      'modifier-cas-usage' => "Modification d'une démarche",
      'nouvelle-solution' => "Référencement d'une nouvelle solution",
      'modifier-solution' => "Modification d'une fiche solution",
      'nouvel-article' => "Proposition d'un nouvel article",
      'modifier-article' => "Modification d'un article",
      'autre-contenu' => 'Erreur de contenu',
      'probleme-site' => "Problème technique ou d'accessibilité",
      'autre' => 'Prise de contact - autre sujet'
    }.each do |besoin, objet|
      it "donne l’adresse et l’objet « #{objet} » sur /contact/#{besoin}" do
        get contact_path(besoin)

        expect(response.parsed_body.at('#objet-message').text).to eq(objet)
        expect(response.body).to include("mailto:#{email}")
      end
    end
  end

  describe 'fiche d’origine' do
    it 'cite le cas d’usage, avec son picto, dans l’objet et le message' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', icone: '🍽️', visible: true)

      get contact_path('modifier-cas-usage', demarche: 'cantine')

      expect(response.body).to include('Fiche concernée : 🍽️ Cantine à 1€ – http://www.example.com/demarches/cantine')
      expect(response.parsed_body.at('#objet-message').text).to eq("Modification d'une démarche : 🍽️ Cantine à 1€")
    end

    it 'ne demande plus le nom et l’URL du cas d’usage une fois celui-ci choisi' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)

      get contact_path('modifier-cas-usage')
      expect(response.parsed_body.at('#modele-message').text).to include("Le nom et l'URL de la démarche concernée")

      get contact_path('modifier-cas-usage', demarche: 'cantine')
      modele = response.parsed_body.at('#modele-message').text
      expect(modele).not_to include("Le nom et l'URL de la démarche concernée")
      expect(modele).to include('Votre organisation et votre fonction', 'Vos propositions pour améliorer la fiche')
      expect(CGI.unescape(response.parsed_body.at('a[href^="mailto:"]')['href'])).not_to include("Le nom et l'URL")
    end

    it 'propose de choisir la solution publiée, avec le nom court de son opérateur' do
      dinum = Organisation.create!(nom: 'DINUM', nom_long: 'Direction interministérielle du numérique')
      Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle', organisations: [dinum])
      Solution.create!(nom: 'Annuaire', slug: 'annuaire', visible: true, categorie: 'brique_logicielle')
      Solution.create!(nom: 'API hors fiche', visible: true, categorie: 'api')
      Solution.create!(nom: 'Brouillon', slug: 'brouillon', categorie: 'brique_logicielle')

      get contact_path('modifier-solution')

      formulaire = response.parsed_body.at('form[method="get"][action="/contact/modifier-solution"]')
      expect(formulaire['data-turbo-frame']).to eq('modele-de-mail')
      options = formulaire.css('select[name="solution"] option').map { |option| [option['value'], option.text] }
      expect(options).to eq([['', 'Sélectionner une solution'], %w[annuaire Annuaire], ['babily', 'Babily – DINUM']])
      expect(formulaire.at('select[name="solution"]')['data-action']).to eq('change->form#submit')
      expect(formulaire.at('label[for="solution"]').text).to include('Solution concernée', 'se met à jour selon votre choix')
      expect(formulaire.at('noscript button[type="submit"]')).to be_present
      expect(response.parsed_body.at('turbo-frame#modele-de-mail #modele-message').text)
        .to include("Le nom de la solution et l'URL de sa fiche")
    end

    it 'garde la liste des solutions, avec la solution choisie présélectionnée et le modèle allégé' do
      Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle')

      get contact_path('modifier-solution', solution: 'babily')

      expect(response.parsed_body.at('select[name="solution"] option[selected]')['value']).to eq('babily')
      expect(response.parsed_body.at('#modele-message').text).not_to include("Le nom de la solution et l'URL de sa fiche")
    end

    it 'cite la solution et son opérateur dans l’objet et le message' do
      dinum = Organisation.create!(nom: 'DINUM', nom_long: 'Direction interministérielle du numérique')
      Solution.create!(nom: 'Babily', slug: 'babily', visible: true, categorie: 'brique_logicielle', organisations: [dinum])

      get contact_path('modifier-solution', solution: 'babily')

      expect(response.parsed_body.at('#modele-message').text)
        .to include('Fiche concernée : Babily – DINUM – http://www.example.com/solutions/babily')
      expect(response.parsed_body.at('#objet-message').text).to eq("Modification d'une fiche solution : Babily – DINUM")
      expect(CGI.unescape(response.parsed_body.at('a[href^="mailto:"]')['href'])).to include('fiche solution : Babily – DINUM')
    end

    it 'propose de choisir le cas d’usage publié quand on n’arrive pas d’une fiche' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', icone: '🍽️', visible: true)
      Demarche.create!(nom: 'Bourse', slug: 'bourse', visible: true)
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon')

      get contact_path('modifier-cas-usage')

      formulaire = response.parsed_body.at('form[method="get"][action="/contact/modifier-cas-usage"]')
      options = formulaire.css('select[name="demarche"] option').map { |option| [option['value'], option.text] }
      expect(options).to eq([['', 'Sélectionner une démarche'], %w[bourse Bourse], ['cantine', '🍽️ Cantine à 1€']])
      expect(formulaire.at('label[for="demarche"]').text).to include('Démarche concernée',
        'Le modèle de mail ci-dessous se met à jour selon votre choix.')
      expect(formulaire.at('noscript button[type="submit"]').text.strip).to eq('Préremplir le message')
    end

    it 'met à jour le modèle de mail dès qu’on choisit le cas d’usage' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)

      get contact_path('modifier-cas-usage')

      formulaire = response.parsed_body.at('form[action="/contact/modifier-cas-usage"]')
      expect(formulaire['data-controller']).to eq('form')
      expect(formulaire['data-turbo-frame']).to eq('modele-de-mail')
      expect(formulaire['data-turbo-action']).to eq('advance')
      expect(formulaire.at('select[name="demarche"]')['data-action']).to eq('change->form#submit')
      expect(response.parsed_body.at('turbo-frame#modele-de-mail a[href^="mailto:"]')).to be_present
    end

    it 'garde la liste, avec le cas d’usage choisi présélectionné' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)

      get contact_path('modifier-cas-usage', demarche: 'cantine')

      expect(response.parsed_body.at('select[name="demarche"] option[selected]')['value']).to eq('cantine')
    end

    it 'ignore une fiche inconnue, non publiée, d’un autre type ou qui n’est pas un texte' do
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon')
      Solution.create!(nom: 'Solution homonyme', slug: 'cantine', visible: true, categorie: 'brique_logicielle')

      ['/contact/modifier-cas-usage?demarche=brouillon', '/contact/modifier-cas-usage?demarche=inconnue',
       '/contact/modifier-cas-usage?solution=cantine', '/contact/modifier-cas-usage?demarche[x]=1',
       '/contact/modifier-solution?solution[]=cantine'].each do |chemin|
        get chemin

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Fiche concernée', 'Brouillon')
        expect(response.parsed_body.at('#objet-message').text).not_to include('Solution homonyme')
      end
    end
  end

  describe 'GET /contact/autre' do
    it 'rappelle les autres sujets, avec un lien, avant le modèle de mail' do
      get contact_path('autre')

      corps = response.body
      expect(corps).to include('Veuillez vérifier que votre demande ne concerne aucun des sujets suivants :')
      %w[contenu demarche-personnelle question-api probleme-site].each do |besoin|
        expect(corps).to include(%(href="/contact/#{besoin}"))
      end
      expect(corps).not_to include('href="/contact/autre"')
      expect(corps.index('Veuillez vérifier')).to be < corps.index('id="modele-message"')
    end
  end

  describe 'réponses sans contact' do
    it 'oriente les usagers vers leur administration, sans adresse' do
      get contact_path('demarche-personnelle')

      expect(response.body).to include('Nous ne sommes pas en mesure de vous aider à ce sujet.')
      expect(response.body).to include('href="https://www.service-public.fr"')
      expect(response.body).not_to include(email, 'mailto:')
    end

    it 'oriente vers les fournisseurs d’API, sans proposer de contact' do
      get contact_path('question-api')

      expect(response.parsed_body.at('h2.fr-h3').text).to eq("J'ai une question sur une API ou un jeu de données")
      expect(response.body).to include('href="https://www.data.gouv.fr"', 'href="/demarches"')
      expect(response.body).not_to include(email, 'mailto:')
    end
  end

  it 'nomme l’étape dans le titre de l’onglet' do
    get contact_path('question-api')
    expect(response.body).to include('<title>J&#39;ai une question sur une API ou un jeu de données - Nous contacter | Simplifions.data.gouv.fr</title>')

    get contact_path('contenu')
    expect(response.body).to include('<title>Proposer ou corriger un contenu du site - Nous contacter | Simplifions.data.gouv.fr</title>')
  end

  it 'renvoie 404 pour un besoin inconnu' do
    get '/contact/nimporte-quoi'

    expect(response).to have_http_status(:not_found)
  end
end
