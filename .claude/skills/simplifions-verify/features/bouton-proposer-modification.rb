require_relative '../harness'

DOSSIER = 'bouton-proposer-modification'.freeze
SLUG = 'tarification-daccueil-du-jeune-enfant-par-un-eaje-beneficiant-de-la-psu'.freeze
FENETRES = { 'Phone' => [390, 844], 'Narrow' => [500, 844], 'Computer' => [1280, 800] }.freeze

MESURE = <<~JS.freeze
  (() => {
    const el = document.activeElement
    const panneau = document.getElementById('solutions-integratrices')
    const bouton = document.querySelector('.bouton-proposer-modification').getBoundingClientRect()
    const r = el.getBoundingClientRect()
    const largeur = Math.max(0, Math.min(r.right, bouton.right) - Math.max(r.left, bouton.left))
    const hauteur = Math.max(0, Math.min(r.bottom, bouton.bottom) - Math.max(r.top, bouton.top))
    return {
      dans_panneau: panneau.contains(el) && el !== panneau,
      nom: (el.getAttribute('aria-label') || el.innerText || el.tagName).trim().replace(/\\s+/g, ' ').slice(0, 40),
      chevauchement: Math.round(largeur * hauteur),
      bouton: Math.round(bouton.height)
    }
  })()
JS

def arrets_du_panneau(page)
  page.execute_script("document.querySelector('[role=tab][aria-controls=solutions-integratrices]').focus()")
  arrets = []
  200.times do
    page.send_keys(:tab)
    sleep 0.2
    arret = page.evaluate_script(MESURE)
    break if arrets.any? && !arret['dans_panneau']

    arrets << arret if arret['dans_panneau']
  end
  arrets
end

def verifier(page, largeur, hauteur)
  page.current_window.resize_to(largeur, hauteur)
  page.visit("/demarches/#{SLUG}#solutions-integratrices")
  page.find('#solutions-integratrices.fr-tabs__panel--selected', wait: 20)
  Verify.evidence(DOSSIER, page, "#{largeur}-depart")
  arrets = arrets_du_panneau(page)
  caches = arrets.select { it['chevauchement'].positive? }
  hauteur_bouton = arrets.map { it['bouton'] }.min
  Verify.evidence(DOSSIER, page, "#{largeur}-dernier-arret",
    "fenetre=#{page.evaluate_script('innerWidth')} arrets=#{arrets.size} chevauchent=#{caches.size} bouton=#{hauteur_bouton}px")
  raise "aucun arrêt dans le panneau à #{largeur}" if arrets.empty?
  raise "#{caches.size}/#{arrets.size} arrêts sous le bouton : #{caches.map { it['nom'] }.join(', ')}" if caches.any?
  raise "bouton haut de #{hauteur_bouton}px à #{largeur}" if hauteur_bouton < 40
end

Verify.drive(__FILE__) do |page|
  FENETRES.each { |label, (largeur, hauteur)| Verify.check(label) { verifier(page, largeur, hauteur) } }
  Verify.check('Proof') do
    Verify.captures_presentes(DOSSIER, FENETRES.values.flat_map { |(largeur)| ["#{largeur}-depart", "#{largeur}-dernier-arret"] })
  end
end
