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

        expect(helper.matomo_evenement('Recherche endpoint', 'API Particulier', api))
          .to eq(matomo_action: 'Recherche endpoint', matomo_nom: "API Particulier [API, #{libelle}]")
      end
    end

    it "omet l'accès quand data.gouv ne l'a pas encore donné" do
      expect(helper.matomo_evenement('Recherche endpoint', 'API Particulier', api)[:matomo_nom])
        .to eq('API Particulier [API]')
    end

    it 'distingue un jeu de données et ajoute l’origine en dernier' do
      jeu = Solution.new(nom: 'Base SIRENE', categorie: 'base_de_donnees', datagouv_acces: 'open')

      expect(helper.matomo_evenement('Sortie', 'Base SIRENE', jeu, 'démarche')[:matomo_nom])
        .to eq('Base SIRENE [Jeu de données, ouvert, démarche]')
    end
  end

  describe '#matomo_sortie_datagouv' do
    it 'compte une fiche ouverte avec compte comme accès ouvert' do
      api.datagouv_acces = 'open_with_account'

      expect(helper.matomo_sortie_datagouv('API Particulier', api, 'démarche', 'tableau'))
        .to eq(matomo_action: 'Sortie fiche data.gouv accès ouvert',
          matomo_nom: 'API Particulier [API, ouvert avec compte, démarche, tableau]')
    end

    it 'sépare une fiche restreinte' do
      api.datagouv_acces = 'restricted'

      expect(helper.matomo_sortie_datagouv('API Particulier', api, 'démarche', 'documentation')[:matomo_action])
        .to eq('Sortie fiche data.gouv accès restreint')
    end
  end
end
