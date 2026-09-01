require 'rails_helper'

RSpec.describe DataserviceCardComponent, type: :component do
  describe '.pour' do
    let(:dinum) { Organisation.new(nom: 'DINUM', nom_long: 'Direction interministérielle du numérique') }
    let(:api) do
      Solution.new(nom: 'API Quotient familial', categorie: 'api', uid_datagouv: '672cf9', organisations: [dinum])
    end

    it 'rend la carte du site actuel, avec des placeholders pour le type d’accès et le logo' do
      render_inline(described_class.pour(api))

      expect(page).to have_css('.fr-badge', text: 'À définir')
      expect(page).to have_css("img.dataservice-card__logo[src='https://placehold.co/40x40'][alt='']")
      expect(page).to have_css("h3 a[target='_blank'][rel='noopener noreferrer']", text: 'API Quotient familial')
      expect(page).to have_link(href: 'https://www.data.gouv.fr/fr/dataservices/672cf9')
      expect(page).to have_css('.dataservice-card__org', text: 'Direction interministérielle du numérique')
      expect(page).to have_css('.fr-link', text: "Voir l'API sur Data.gouv.fr")
    end

    it 'adapte le libellé du lien et le niveau de titre pour un jeu de données sans organisation' do
      jeu = Solution.new(nom: 'Base SIRENE', categorie: 'base_de_donnees', uid_datagouv: 'sirene')
      render_inline(described_class.pour(jeu, heading: 'h6'))

      expect(page).to have_css('h6 a', text: 'Base SIRENE')
      expect(page).to have_link(href: 'https://www.data.gouv.fr/fr/datasets/sirene')
      expect(page).to have_css('.fr-link', text: 'Voir le jeu de données sur Data.gouv.fr')
      expect(page).to have_no_css('.dataservice-card__org')
    end
  end

  it 'rend une carte renseignée à la main avec badge restreint, logo et description' do
    render_inline(described_class.new(api: {
      title: 'API Impôt particulier', url: 'https://www.data.gouv.fr/fr/dataservices/x', org: 'DGFiP',
      logo: 'https://example.test/logo.png', restricted: true, description: 'Échange de données fiscales.'
    }))

    expect(page).to have_css('.fr-badge.fr-badge--info', text: 'API restreinte')
    expect(page).to have_css("img[src='https://example.test/logo.png']")
    expect(page).to have_css('.dataservice-card__desc', text: 'Échange de données fiscales.')
    expect(page).to have_no_text('À définir')
  end
end
