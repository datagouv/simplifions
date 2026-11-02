require 'rails_helper'

RSpec.describe MatomoHelper do
  let(:api) { Solution.new(nom: 'API Particulier', categorie: 'api') }

  describe '#matomo_evenement' do
    {
      %w[open] => 'ouvert',
      %w[open_with_account] => 'ouvert avec compte',
      %w[restricted yes] => 'restreint public',
      %w[restricted under_condition] => 'restreint public sous conditions',
      %w[restricted] => 'restreint'
    }.each do |(acces, acteurs_publics), libelle|
      it "nomme l'accès #{[acces, acteurs_publics].compact.join(' + ')} « #{libelle} »" do
        api.assign_attributes(datagouv_acces: acces, datagouv_acces_acteurs_publics: acteurs_publics)

        expect(helper.matomo_evenement('Filtrer les endpoints', 'API Particulier', api))
          .to eq(matomo_action: 'Filtrer les endpoints', matomo_nom: "API Particulier [API, #{libelle}]")
      end
    end

    it "omet l'accès quand data.gouv ne l'a pas encore donné" do
      expect(helper.matomo_evenement('Filtrer les endpoints', 'API Particulier', api)[:matomo_nom])
        .to eq('API Particulier [API]')
    end

    it 'distingue un jeu de données' do
      jeu = Solution.new(nom: 'Base SIRENE', categorie: 'base_de_donnees', datagouv_acces: 'open')

      expect(helper.matomo_evenement('Ouvrir la fiche data.gouv', 'Base SIRENE', jeu)[:matomo_nom])
        .to eq('Base SIRENE [Jeu de données, ouvert]')
    end

    it 'dit si la solution est publique, comme son badge opérateur' do
      api.organisations = [Organisation.new(nom: 'DINUM', public_ou_prive: 'Public')]

      expect(helper.matomo_evenement('Ouvrir la fiche data.gouv', 'API Particulier', api)[:matomo_nom])
        .to eq('API Particulier [API, publique]')
    end

    it 'dit si la solution est privée, avec sa catégorie' do
      logiciel = Solution.new(nom: 'Acheteza', categorie: 'logiciel_metier_cle_en_main',
        organisations: [Organisation.new(nom: 'Éditeur', public_ou_prive: 'Privé')])

      expect(helper.matomo_fiche_solution(logiciel))
        .to eq(matomo_action: 'Ouvrir la fiche solution', matomo_nom: 'Acheteza [Logiciel métier, privée]')
    end

    it 'garde le seul nom quand rien ne le précise' do
      expect(helper.matomo_fiche_solution(Solution.new(nom: 'Sans catégorie'))[:matomo_nom]).to eq('Sans catégorie')
    end
  end

  describe '#matomo_zone' do
    it 'donne la zone et le cas d’usage ou la fiche concernés' do
      expect(helper.matomo_zone("Cas d'usage", 'Cantine à 1 €'))
        .to eq(matomo_zone: "Cas d'usage", matomo_contexte: 'Cantine à 1 €')
    end

    it 'omet le contexte quand la zone suffit' do
      expect(helper.matomo_zone('Solution › Intégratrices')).to eq(matomo_zone: 'Solution › Intégratrices')
    end
  end

  describe '#matomo_sortie_datagouv' do
    it 'garde l’accès de la fiche data.gouv dans le nom' do
      api.datagouv_acces = 'open_with_account'

      expect(helper.matomo_sortie_datagouv('API Particulier', api))
        .to eq(matomo_action: 'Ouvrir la fiche data.gouv', matomo_nom: 'API Particulier [API, ouvert avec compte]')
    end
  end

  describe '#matomo_fiche_solution' do
    it 'range une brique dont le type de solution est une API parmi les API' do
      bouquet = Solution.new(nom: 'Bouquet API Particulier', categorie: 'brique_logicielle', types_solution: ['API'])

      expect(helper.matomo_fiche_solution(bouquet))
        .to eq(matomo_action: 'Ouvrir la fiche solution', matomo_nom: 'Bouquet API Particulier [API]')
    end

    it 'mesure aussi les autres fiches, avec leur catégorie' do
      site = Solution.new(nom: 'Portail', categorie: 'site_de_consultation', types_solution: ['Portail agent'])

      expect(helper.matomo_fiche_solution(site)[:matomo_nom]).to eq('Portail [Portail de consultation]')
    end
  end
end
