require_relative '../harness'

Verify.drive(__FILE__) do |page|
  titre = Verify.check('Open a fiche') do
    page.visit('/demarches')
    page.first('h3 a').text.tap do |titre|
      page.click_link titre
      page.assert_selector 'h1', text: titre, wait: 15
    end
  end

  section = Verify.check('Find the data') do
    page.assert_selector '[role=tab][aria-selected=true]', text: 'Données disponibles et utiles'
    page.find('#donnees-disponibles')
  end

  Verify.check('Unfold') do
    section.first("button[aria-expanded='false']").click
    section.assert_selector "button[aria-expanded='true']"
  end

  Verify.check('Proof') do
    demarche = Demarche.visibles.find_by!(nom: Demarche.visibles.find { |d| d.titre == titre }.nom)
    Verify.evidence('fiche-cas-usage', page, 'accordeon-ouvert',
      "slug=#{demarche.slug} recommandations_niveau_2=#{demarche.recommandations.visibles.niveau_2.count} " \
      "accordeons_ouverts=#{section.all('button[aria-expanded=true]').size}")
  end
end
