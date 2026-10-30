require_relative '../harness'

Verify.drive(__FILE__) do |page|
  data_subvention = Solution.visibles.find_by!(slug: 'data-subvention')

  Verify.check('Cards from the base') do
    page.visit('/articles/guide-base-petites-collectivites')
    encart = page.find('.spotlight', text: 'Data.Subvention')
    operateur = data_subvention.organisations.first.nom
    encart.assert_selector :link, data_subvention.nom, href: '/solutions/data-subvention'
    encart.assert_selector '.fr-badge b', text: operateur
    cantine = Demarche.visibles.find_by!(slug: 'tarification-cantine-scolaire-a-1eur')
    page.assert_selector :link, cantine.titre, href: '/demarches/tarification-cantine-scolaire-a-1eur', minimum: 1
    Verify.evidence('article-cartes', page, 'cartes-de-la-base',
      "badge=#{encart.find('.fr-badge').text.squish} base=#{operateur} cantine=#{cantine.titre}")
  end

  Verify.check('Hidden record') do
    data_subvention.update_columns(visible: false)
    page.visit('/articles/guide-base-petites-collectivites')
    page.assert_selector 'h1', text: 'Guide de base pour les petites collectivités'
    page.assert_no_selector '.fr-card a[href="/solutions/data-subvention"]'
  end

  Verify.check('Proof') do
    Verify.evidence('article-cartes', page, 'fiche-cachee', "visible=#{data_subvention.reload.visible} carte=absente")
  end
ensure
  data_subvention&.update_columns(visible: true)
end
