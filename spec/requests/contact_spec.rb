require 'rails_helper'

RSpec.describe 'Contact' do
  let(:email) { 'contact@example.test' }

  describe 'GET /contact' do
    before { get contact_path }

    it 'propose les besoins de la première étape, sans FAQ ni adresse' do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<legend class="fr-fieldset__legend" id="choix-besoin-legende">Quel est votre besoin ?</legend>')
      BesoinContact.racines.each do |besoin|
        expect(response.body).to include(%(value="#{besoin.cle}"))
      end
      expect(response.body.scan('fr-radio-group fr-radio-rich').size).to eq(BesoinContact.racines.size)
      expect(response.body).to match(%r{<use class="fr-artwork-major" href="/assets/artwork/pictograms/digital/avatar-\h+\.svg#artwork-major">})
      expect(response.body).not_to include('fr-stepper')
      expect(response.body).not_to include(email)
    end

    it 'reste indexable' do
      expect(response.body).not_to include('<meta name="robots"')
    end
  end

  describe 'GET /contact?besoin=contenu' do
    it 'précise la demande de contenu, sans donner l’adresse' do
      get contact_path(besoin: 'contenu')

      expect(response.body).to include('Précisez votre demande')
      %w[nouveau-cas-usage modifier-cas-usage nouvelle-solution modifier-solution
         nouvel-article modifier-article autre-contenu].each do |cle|
        expect(response.body).to include(%(value="#{cle}"))
      end
      legendes = response.body.scan(%r{<span id="groupe-[^"]+">([^<]+)</span>})
        .flatten.map { |legende| CGI.unescapeHTML(legende) }
      expect(legendes).to eq(["Cas d'usages", 'Solutions', 'Articles', 'Autre contenu'])
      expect(response.body).to include('title="Voir les cas d&#39;usages - nouvelle fenêtre" href="/demarches"')
      expect(response.body).to include('href="/solutions"', 'href="/articles"')
      expect(response.body).to include('<legend class="fr-fieldset__legend fr-sr-only" id="choix-besoin-legende">Précisez votre demande</legend>')
      expect(response.body).to include('<meta name="robots" content="noindex">')
      expect(response.body).not_to include(email)
    end
  end

  describe 'étape finale' do
    before do
      TypeActeur.create!(nom: 'Communes et groupements de communes')
      TypeActeur.create!(nom: 'Caisses des écoles')
      Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')
      Vocabulaire.create!(nom: 'Associations', slug: 'associations', categorie: 'usager')
    end

    it 'liste les informations à transmettre mais demande une action avant de donner l’adresse' do
      get contact_path(besoin: 'nouveau-cas-usage')

      expect(response.body).to include('Informations à nous transmettre')
      expect(response.body).to include('<li>Le public concerné</li>', '<li>Les types d&#39;administrations concernées</li>')
      expect(response.body).not_to include('Caisses des écoles', 'Particuliers')
      expect(response.body).to include('href="/doctrine-referencement-cas-usages"')
      expect(response.body).to include('<input type="hidden" name="adresse" value="1" />')
      expect(response.body).to include("Afficher l'adresse e-mail</button>")
      expect(response.body).not_to include(email)
    end

    it 'donne l’adresse et un mail pré-rempli une fois le formulaire envoyé' do
      get contact_path(besoin: 'nouveau-cas-usage', adresse: 1)

      expect(response.body).to include("Envoyez votre message à <strong>#{email}</strong>")
      expect(response.body).to include(%(data-copier-texte-param="#{email}" data-copier-confirmation-param="Adresse copiée.">Copier l'adresse</button>))
      expect(response.body).to include('<input class="fr-input" id="objet-message" type="text" readonly ' \
                                       'value="[Simplifions.data] Proposition d&#39;un nouveau cas d&#39;usage">')
      expect(response.body).to include("href=\"mailto:#{email}?body=Bonjour%2C")
      expect(response.body).to include('&amp;subject=%5BSimplifions.data%5D%20Proposition%20d%27un%20nouveau%20cas%20d%27usage"')
      expect(response.body).to include(ERB::Util.html_escape(
        "Les types d'administrations concernées (gardez les mentions utiles) :\n- Communes et groupements de communes\n- Caisses des écoles"
      ))
      expect(response.body).to include("Écrire à l'équipe")
      expect(response.body).to include('data-controller="copier"')
      expect(response.body).to include('data-copier-texte-param="[Simplifions.data] Proposition d&#39;un nouveau cas d&#39;usage"')
      expect(response.body).to include("Copier l'objet du message</button>", 'Copier le modèle de message</button>')
    end

    it 'cite la fiche d’origine dans le mail' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)

      get contact_path(besoin: 'modifier-cas-usage', demarche: 'cantine')
      expect(response.body).to include('Fiche concernée : <a href="http://www.example.com/demarches/cantine">Cantine à 1€</a>')
      expect(response.body).to include('<input type="hidden" name="demarche" value="cantine" />')

      get contact_path(besoin: 'modifier-cas-usage', demarche: 'cantine', adresse: 1)
      expect(response.body).to include('Fiche concernée : Cantine à 1€ – http://www.example.com/demarches/cantine')
      expect(response.body).to include('.data] Modification d&#39;un cas d&#39;usage : Cantine à 1€')
    end

    it 'ignore une fiche inconnue ou non publiée' do
      Demarche.create!(nom: 'Brouillon', slug: 'brouillon')

      get contact_path(besoin: 'modifier-cas-usage', demarche: 'brouillon', adresse: 1)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Fiche concernée')
      expect(response.body).not_to include('Brouillon')
    end

    it 'ne cherche pas le slug d’une démarche parmi les solutions' do
      Demarche.create!(nom: 'Cantine à 1€', slug: 'cantine', visible: true)
      Solution.create!(nom: 'Solution homonyme', slug: 'cantine', visible: true)

      get contact_path(besoin: 'contenu', demarche: 'cantine')
      expect(response.body).to include('<input type="hidden" name="demarche" value="cantine" />')

      get contact_path(besoin: 'modifier-solution', demarche: 'cantine', adresse: 1)
      expect(response.body).not_to include('Fiche concernée', 'Solution homonyme')
    end

    it 'sépare les lignes du mail par CRLF dans le lien, comme le demande la RFC 6068' do
      get contact_path(besoin: 'autre', adresse: 1)

      expect(response.body).to include('body=Bonjour%2C%0D%0A%0D%0A')
      expect(response.body).to include("Bonjour,\n\n")
    end

    it 'prévient quand l’adresse n’est pas configurée' do
      allow(Rails.configuration.x).to receive(:contact_email).and_return(nil)

      get contact_path(besoin: 'autre', adresse: 1)

      expect(response.body).to include('Adresse de contact indisponible')
      expect(response.body).not_to include('mailto:')
    end
  end

  describe 'GET /contact?besoin=autre' do
    it 'rappelle les autres sujets, avec un lien, avant les informations à transmettre' do
      get contact_path(besoin: 'autre')

      corps = response.body
      expect(corps).to include('Veuillez vérifier que votre demande ne concerne aucun des sujets suivants :')
      (BesoinContact.racines.map(&:cle) - ['autre']).each do |cle|
        expect(corps).to include(%(href="/contact?besoin=#{cle}#parcours"))
      end
      expect(corps).not_to include('href="/contact?besoin=autre#parcours"')
      expect(corps.index('Veuillez vérifier')).to be < corps.index('Informations à nous transmettre')
      expect(corps).not_to include(email)
    end
  end

  describe 'réponses sans contact' do
    it 'oriente les usagers vers leur administration, sans adresse' do
      get contact_path(besoin: 'demarche-personnelle', adresse: 1)

      expect(response.body).to include('Nous ne sommes pas en mesure de vous aider à ce sujet.')
      expect(response.body).to include('href="https://www.service-public.fr"')
      expect(response.body).not_to include(email)
      expect(response.body).not_to include('mailto:')
    end

    it 'oriente vers les fournisseurs d’API, sans proposer de contact' do
      get contact_path(besoin: 'question-api', adresse: 1)

      expect(response.body).to include('<h2 class="fr-h3">J&#39;ai une question sur une API ou un jeu de données</h2>')
      expect(response.body).to include('href="https://www.data.gouv.fr"', 'href="/demarches"')
      expect(response.body).not_to include(email)
      expect(response.body).not_to include('mailto:', 'Afficher l&#39;adresse')
    end
  end

  it 'ignore une fiche d’origine qui n’est pas un texte' do
    get '/contact?besoin=modifier-cas-usage&demarche[x]=1'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('href="/contact?besoin=contenu#parcours"')

    get '/contact?besoin=contenu&solution[]=cantine'
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('name="solution"')
  end

  it 'revient à la première étape pour un besoin inconnu' do
    get contact_path(besoin: 'nimporte-quoi')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Quel est votre besoin ?')
  end

  it 'titre les étapes de contact et de réponse, pas les étapes de choix' do
    get contact_path(besoin: 'modifier-cas-usage')
    expect(response.body).to include('<h2 class="fr-h3">Proposer une modification d&#39;un cas d&#39;usage existant</h2>')

    get contact_path(besoin: 'demarche-personnelle')
    expect(response.body).to include('<h2 class="fr-h3">J&#39;ai une question sur ma propre démarche administrative</h2>')

    get contact_path(besoin: 'contenu')
    expect(response.body).not_to include('<h2 class="fr-h3">Proposer ou corriger un contenu du site</h2>')
  end

  it 'permet de revenir à l’étape précédente' do
    get contact_path(besoin: 'modifier-solution')

    expect(response.body).to include('href="/contact?besoin=contenu#parcours"')
  end
end
