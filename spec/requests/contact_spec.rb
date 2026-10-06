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

    it 'reste indexable' do
      expect(response.body).not_to include('<meta name="robots"')
    end
  end

  describe 'GET /contact/contenu' do
    before { get contact_path('contenu') }

    it 'précise la demande de contenu en sept besoins groupés, sans donner l’adresse' do
      expect(response.body).to include('Précisez votre demande')
      expect(titres_des_tuiles).to eq([
        ['/contact/nouveau-cas-usage', "Proposer un nouveau cas d'usage"],
        ['/contact/modifier-cas-usage', "Proposer une modification d'un cas d'usage existant"],
        ['/contact/nouvelle-solution', 'Référencer une nouvelle solution'],
        ['/contact/modifier-solution', "Proposer une modification d'une fiche solution existante"],
        ['/contact/nouvel-article', 'Proposer un nouvel article'],
        ['/contact/modifier-article', "Proposer une modification d'un article existant"],
        ['/contact/autre-contenu', "Proposer la modification d'un autre contenu"]
      ])
      expect(response.parsed_body.css('h3').map(&:text)).to eq(["Cas d'usages", 'Solutions', 'Articles', 'Autre contenu'])
      expect(response.body).to include('title="Voir les cas d&#39;usages - nouvelle fenêtre"')
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

    it 'donne les ressources à vérifier, les informations, l’adresse et un mail prérempli' do
      get contact_path('nouveau-cas-usage')

      expect(response.parsed_body.at('h2.fr-h3').text).to eq("Proposer un nouveau cas d'usage")
      expect(response.body).to include('Avant de nous écrire :', 'href="/doctrine-referencement-cas-usages"')
      expect(response.body).to include('Informations à nous transmettre')
      expect(response.body).to include('<li>Le public concerné</li>', '<li>Les types d&#39;administrations concernées</li>')
      expect(response.body).to include("Envoyez votre message à <strong>#{email}</strong>")
      expect(response.body).to include('<input class="fr-input" id="objet-message" type="text" readonly ' \
                                       'value="[Simplifions.data] Proposition d&#39;un nouveau cas d&#39;usage">')
      expect(response.body).to include("href=\"mailto:#{email}?body=Bonjour%2C")
      expect(response.body).to include('&amp;subject=%5BSimplifions.data%5D%20Proposition%20d%27un%20nouveau%20cas%20d%27usage"')
      expect(response.body).to include(ERB::Util.html_escape(
        "Les types d'administrations concernées (gardez les mentions utiles) :\n- Communes et groupements de communes\n- Caisses des écoles"
      ))
      expect(response.body).to include(ERB::Util.html_escape(
        "Le public concerné (gardez les mentions utiles) :\n- Particuliers\n- Associations"
      ))
      expect(response.body).to include("Écrire à l'équipe")
      expect(response.body).to include('href="/contact/contenu"')
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
      modele = response.parsed_body.at('textarea#modele-message').text
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
      'modifier-cas-usage' => "Modification d'un cas d'usage",
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

        expect(response.body).to include(ERB::Util.html_escape("[Simplifions.data] #{objet}"))
        expect(response.body).to include("mailto:#{email}")
      end
    end
  end

  describe 'GET /contact/autre' do
    it 'rappelle les autres sujets, avec un lien, avant les informations à transmettre' do
      get contact_path('autre')

      corps = response.body
      expect(corps).to include('Veuillez vérifier que votre demande ne concerne aucun des sujets suivants :')
      %w[contenu demarche-personnelle question-api probleme-site].each do |besoin|
        expect(corps).to include(%(href="/contact/#{besoin}"))
      end
      expect(corps).not_to include('href="/contact/autre"')
      expect(corps.index('Veuillez vérifier')).to be < corps.index('Informations à nous transmettre')
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
