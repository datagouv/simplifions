require 'rails_helper'

RSpec.describe 'Historique des fiches' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }

  before { sign_in admin }

  it 'note l’admin connecté comme auteur d’une modification' do
    demarche = Demarche.create!(nom: 'Aides')

    patch "/admin/demarches/#{demarche.id}", params: { demarche: { nom: 'Aides sociales' } }

    expect(demarche.versions.last.whodunnit).to eq(admin.id.to_s)
  end

  describe 'page historique' do
    def versions = response.parsed_body.css('main section').map { |version| [version.at_css('h2').text.squish, lignes_de(version)] }

    def lignes_de(version) = version.css('tbody tr').map { |ligne| ligne.css('th, td').map { |cellule| cellule.text.squish } }

    it 'liste les versions d’une solution, la plus récente d’abord, avec leur auteur et chaque champ changé' do
      solution = PaperTrail.request(whodunnit: admin.id.to_s) { Solution.create!(nom: 'API QF', categorie: 'api', cree_le: Time.zone.local(2026, 10, 1, 9)) }
      PaperTrail.request(whodunnit: 'Import Grist') { solution.update!(nom: 'API Quotient familial', france_connectee: true, legende_image: '') }

      get "/admin/historique/solutions/#{solution.id}"

      expect(response).to have_http_status(:ok)
      expect(versions.map(&:first)).to match([%r{\AModification par Import Grist le \d\d/\d\d/\d{4} à \d\d:\d\d\z}, /\ACréation par dorine@example.gouv.fr le /])
      expect(versions.first.last).to eq([['Nom', 'API QF', 'API Quotient familial'], ['API FranceConnectée', 'Non', 'Oui']])
      expect(versions.last.last).to include(['Catégorie de solution', 'Vide', 'API'], ['Date de création', 'Vide', '01/10/2026 à 09:00'])
      expect(versions.last.last.map(&:first)).not_to include('Id', 'Created at')
    end

    it 'nomme le type de recommandation comme le formulaire' do
      recommandation = Recommandation.create!(demarche: Demarche.create!(nom: 'Aides'), solution: Solution.create!(nom: 'API QF', categorie: 'api'), niveau: :niveau_1)
      recommandation.update!(niveau: :niveau_2)

      get "/admin/historique/recommandations/#{recommandation.id}"

      expect(versions.first.last).to eq([['Type de recommandation', 'Donnée utile (API ou jeu de données)', 'Solution recommandée']])
    end

    it 'mène de la fiche à son historique par le fil d’Ariane' do
      solution = Solution.create!(nom: 'API QF', categorie: 'api')
      get "/admin/historique/solutions/#{solution.id}"

      liens = response.parsed_body.css('.fr-breadcrumb__list a').map { |lien| [lien.text, lien['href']] }
      expect(liens).to eq([['Administration', '/admin'], ['Solutions', '/admin/solutions'],
                           ['API QF (API)', "/admin/solutions/#{solution.id}/edit"], ['Historique', nil]])
    end

    it 'dit qu’une fiche n’a pas encore de version' do
      demarche = PaperTrail.request(enabled: false) { Demarche.create!(nom: 'Aides') }
      get "/admin/historique/demarches/#{demarche.id}"

      expect(response.parsed_body.at_css('main').text).to include('Aucune version enregistrée pour cette fiche.')
    end

    it 'refuse une table hors de l’administration' do
      get "/admin/historique/admins/#{admin.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'colonne de droite' do
    def colonne = response.parsed_body.at_css('aside[aria-labelledby="etat-et-actions"]')

    it 'dit qui a modifié chaque fiche en dernier et mène à son historique' do
      lignes = PaperTrail.request(whodunnit: admin.id.to_s) do
        api_qf = Solution.create!(nom: 'API QF', categorie: 'api')
        { 'demarches' => Demarche.create!(nom: 'Aides'), 'solutions' => api_qf,
          'recommandations' => Recommandation.create!(demarche: Demarche.create!(nom: 'Cantine'), solution: api_qf, niveau: :niveau_1),
          'integrations' => Integration.create!(integratrice: Solution.create!(nom: 'Bouquet'), integree: api_qf, type_integration: 'consomme'),
          'organisations' => Organisation.create!(nom: 'DINUM'), 'types_acteurs' => TypeActeur.create!(nom: 'Communes'),
          'vocabulaires' => Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager') }
      end
      PaperTrail.request(whodunnit: 'Import Grist') { lignes['demarches'].update!(nom: 'Aides sociales') }

      lignes.each do |chemin, ligne|
        get "/admin/#{chemin}/#{ligne.id}/edit"
        auteur = chemin == 'demarches' ? 'Modifiée par Import Grist le' : 'Créée par dorine@example.gouv.fr le'
        expect(colonne.text.squish).to include(auteur), chemin
        expect(colonne.at_css('a:contains("Historique")')['href']).to eq("/admin/historique/#{chemin}/#{ligne.id}"), chemin
      end
    end

    it 'ne dit rien d’une fiche sans version' do
      demarche = PaperTrail.request(enabled: false) { Demarche.create!(nom: 'Aides') }
      get "/admin/demarches/#{demarche.id}/edit"

      expect(colonne.text).not_to include('Modifiée par', 'Historique')
    end
  end
end
