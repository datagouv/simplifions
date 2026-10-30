require_relative '../harness'

MESURE_SANS_SOLUTION = <<~JS.freeze
  (() => {
    const lignes = [...document.querySelectorAll('#donnees-disponibles .fr-sr-only')]
      .filter(it => it.textContent.includes('Aucune solution référencée')).map(it => it.parentElement)
    const rgb = couleur => couleur.match(/[\\d.]+/g).map(Number)
    const fond = element => {
      for (let it = element; it; it = it.parentElement) {
        const couleur = rgb(getComputedStyle(it).backgroundColor)
        if (couleur[3] !== 0) return couleur
      }
    }
    const luminance = couleur => {
      const [r, g, b] = couleur.slice(0, 3).map(it => it / 255).map(it => it <= 0.03928 ? it / 12.92 : ((it + 0.055) / 1.055) ** 2.4)
      return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    const contraste = (a, b) => {
      const [clair, fonce] = [luminance(a), luminance(b)].sort((x, y) => y - x)
      return Math.round((clair + 0.05) / (fonce + 0.05) * 100) / 100
    }
    lignes[0]?.scrollIntoView({ block: 'center' })
    return lignes.map(ligne => {
      const badge = ligne.querySelector('.fr-badge')
      const style = getComputedStyle(ligne)
      return {
        titre: ligne.textContent.trim().split(/\\s{2,}/)[0],
        couleur: style.color,
        badge: badge && getComputedStyle(badge).color,
        contraste: contraste(rgb(style.color), fond(ligne)),
        cliquable: ligne.closest('button, a') !== null || style.cursor === 'pointer',
        fleche: getComputedStyle(ligne, '::after').display !== 'none'
      }
    })
  })()
JS

def fiche_sans_solution(page)
  page.visit('/demarches/tarification-daccueil-du-jeune-enfant-par-un-eaje-beneficiant-de-la-psu')
  page.find('#donnees-disponibles').assert_text 'Aucun'
  { 'clair-bureau' => [1280, 'light'], 'clair-mobile' => [375, 'light'], 'sombre' => [1280, 'dark'] }
    .each { |nom, (largeur, theme)| verifie_sans_solution(nom, mesure_sans_solution(page, nom, largeur, theme)) }
ensure
  page.current_window.resize_to(1280, 1024)
end

def mesure_sans_solution(page, nom, largeur, theme)
  page.current_window.resize_to(largeur, 1024)
  page.execute_script("document.documentElement.setAttribute('data-fr-theme', '#{theme}')")
  lignes = page.evaluate_script(MESURE_SANS_SOLUTION)
  Verify.evidence('fiche-cas-usage', page, "sans-solution-#{nom}", "largeur=#{page.evaluate_script('innerWidth')} #{lignes}")
  lignes
end

def verifie_sans_solution(nom, lignes)
  raise "#{nom} aucune ligne sans solution" if lignes.empty?

  fautive = lignes.find { |ligne| non_conforme?(ligne) }
  raise "#{nom} #{fautive}" if fautive
end

def non_conforme?(ligne)
  autre_gris = ligne['badge'] && ligne['badge'] != ligne['couleur']
  ligne['contraste'] < 4.5 || ligne['cliquable'] || ligne['fleche'] || autre_gris
end

Verify.drive(__FILE__) do |page|
  titre = Verify.check('Open a fiche') do
    page.visit('/demarches')
    page.first('h3 a').text.tap do |titre|
      page.click_link titre
      page.assert_selector 'h1', text: titre
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

  Verify.check('Sans solution') { fiche_sans_solution(page) }
end
