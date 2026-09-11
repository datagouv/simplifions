require 'rails_helper'

RSpec.describe DataserviceCardComponent, type: :component do
  let(:dinum) { Organisation.new(nom: 'DINUM', nom_long: 'Direction interministérielle du numérique') }
  let(:api) do
    Solution.new(nom: 'API Quotient familial', categorie: 'api', uid_datagouv: '672cf9', organisations: [dinum])
  end

  it 'rend la carte du site actuel avec le titre, le producteur, le logo et le badge d’accès data.gouv' do
    api.assign_attributes(datagouv_titre: 'API Quotient familial | Bouquet API Particulier',
      datagouv_organisation: 'Direction interministérielle du numérique (data.gouv)',
      datagouv_logo: 'https://avatars.test/dinum-100.png', datagouv_organisation_badges: %w[certified public-service],
      datagouv_acces: 'restricted', datagouv_acces_acteurs_publics: 'yes')
    render_inline(described_class.new(api))

    expect(page).to have_css('.fr-badge.fr-badge--success', text: 'API restreinte · accessible aux acteurs publics')
    expect(page).to have_css('.fr-badge .fr-icon-lock-unlock-line[aria-hidden]')
    expect(page).to have_css("img.dataservice-card__logo[src='https://avatars.test/dinum-100.png'][alt='']")
    expect(page).to have_css("h3 a[target='_blank'][rel='noopener noreferrer']",
      text: 'API Quotient familial | Bouquet API Particulier')
    expect(page).to have_link(href: 'https://www.data.gouv.fr/fr/dataservices/672cf9')
    expect(page).to have_css('.dataservice-card__org', text: 'Direction interministérielle du numérique (data.gouv)')
    expect(page).to have_css('.dataservice-card__org .fr-icon-bank-line[aria-hidden]')
    expect(page).to have_css(".dataservice-card__org .fr-icon-checkbox-circle-line[title='Organisation certifiée par data.gouv.fr']")
    expect(page).to have_css('.fr-link', text: "Voir l'API sur Data.gouv.fr")
  end

  it 'ne décore pas une organisation sans badge data.gouv' do
    api.assign_attributes(datagouv_organisation: 'Start-up X', datagouv_organisation_badges: [])
    render_inline(described_class.new(api))

    expect(page).to have_css('.dataservice-card__org', text: 'Start-up X')
    expect(page).to have_no_css('.dataservice-card__org .fr-icon-bank-line')
    expect(page).to have_no_css('.dataservice-card__org .fr-icon-checkbox-circle-line')
  end

  it 'se rabat sur le nom et l’opérateur Grist, sans badge ni logo, tant que data.gouv n’a pas été recopié' do
    render_inline(described_class.new(api))

    expect(page).to have_css('h3 a', text: 'API Quotient familial')
    expect(page).to have_css('.dataservice-card__org', text: 'Direction interministérielle du numérique')
    expect(page).to have_no_css('.fr-badge')
    expect(page).to have_no_css('img')
  end

  it 'adapte le libellé du lien et le niveau de titre pour un jeu de données sans organisation' do
    jeu = Solution.new(nom: 'Base SIRENE', categorie: 'base_de_donnees', uid_datagouv: 'sirene')
    render_inline(described_class.new(jeu, heading: 'h6'))

    expect(page).to have_css('h6 a', text: 'Base SIRENE')
    expect(page).to have_link(href: 'https://www.data.gouv.fr/fr/datasets/sirene')
    expect(page).to have_css('.fr-link', text: 'Voir le jeu de données sur Data.gouv.fr')
    expect(page).to have_no_css('.dataservice-card__org')
  end

  # Mêmes libellés, couleurs et icônes que le site actuel (accessTypeBadge.ts).
  {
    ['api', 'open', nil] => ['API ouverte', 'fr-badge--info', 'fr-icon-arrow-left-right-line'],
    ['base_de_donnees', 'open', nil] => ['Jeu de données ouvert', 'fr-badge--info', 'fr-icon-arrow-left-right-line'],
    ['api', 'open_with_account', nil] => ['API ouverte avec compte', 'fr-badge--info', 'fr-icon-user-line'],
    %w[api restricted under_condition] =>
      ['API restreinte · accessible aux acteurs publics sous conditions', 'fr-badge--green-tilleul-verveine', 'fr-icon-lock-line'],
    %w[base_de_donnees restricted yes] =>
      ['Jeu de données restreint · accessible aux acteurs publics', 'fr-badge--success', 'fr-icon-lock-unlock-line'],
    %w[api restricted no] => ['API en accès restreint', 'fr-badge--orange-terre-battue', 'fr-icon-lock-line'],
    ['api', 'restricted', nil] => ['API en accès restreint', 'fr-badge--orange-terre-battue', 'fr-icon-lock-line']
  }.each do |(categorie, acces, acteurs_publics), (label, classe, icone)|
    it "affiche « #{label} » pour #{categorie} #{acces} #{acteurs_publics}" do
      solution = Solution.new(nom: 'X', categorie:, uid_datagouv: 'x', datagouv_acces: acces,
        datagouv_acces_acteurs_publics: acteurs_publics)
      render_inline(described_class.new(solution))

      expect(page).to have_css(".fr-badge.#{classe} .#{icone}")
      expect(page.find('.fr-badge').text(normalize_ws: true)).to eq(label)
    end
  end

  it 'n’affiche pas de badge pour un jeu de données « ouvert avec compte », statut inexistant côté datasets' do
    jeu = Solution.new(nom: 'X', categorie: 'base_de_donnees', uid_datagouv: 'x', datagouv_acces: 'open_with_account')
    render_inline(described_class.new(jeu))

    expect(page).to have_no_css('.fr-badge')
  end
end
