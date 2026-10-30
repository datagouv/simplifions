require_relative '../harness'

def etat_lire_plus(page, id)
  page.evaluate_script(<<~JS)
    (() => {
      const texte = document.getElementById('#{id}')
      const bouton = document.querySelector("[aria-controls='#{id}']")
      return { replie: texte.classList.contains('lire-plus--replie'), coupe: texte.scrollHeight - texte.clientHeight > 1,
               hauteur: texte.clientHeight, bouton: bouton.checkVisibility() ? bouton.textContent.trim() : null,
               expanded: bouton.getAttribute('aria-expanded'), lien: bouton.classList.contains('fr-link'),
               fondu: getComputedStyle(texte).maskImage !== 'none',
               fleche: ['down', 'up'].find(sens => bouton.classList.contains(`fr-icon-arrow-${sens}-s-line`)) }
    })()
  JS
end

def attendre_lire_plus(page, id, attendu)
  etat = nil
  20.times do
    etat = etat_lire_plus(page, id)
    if attendu.all? { |cle, valeur| etat[cle] == valeur }
      page.execute_script("document.querySelector(\"[aria-controls='#{id}']\").parentElement.scrollIntoView({ block: 'end' })")
      return etat
    end

    sleep 0.25
  end
  raise "#{id} #{etat} au lieu de #{attendu}"
end

def haut_de_section(page, titre)
  page.evaluate_script(<<~JS)
    (() => { const entete = document.querySelector('.affichage-personnalise__entete').getBoundingClientRect()
             const section = [...document.querySelectorAll('h3')].find((h3) => h3.textContent.trim() === '#{titre}').getBoundingClientRect()
             return { haut: Math.round(section.top), sous: Math.max(0, Math.round(entete.bottom)), fenetre: innerHeight } })()
  JS
end

DOSSIER = 'lire-plus'.freeze
CONTEXTE_REPLIE = { 'replie' => true, 'coupe' => true, 'bouton' => 'Lire plus : Contexte' }.freeze
CONTEXTE_DEPLIE = { 'replie' => false, 'bouton' => 'Lire moins : Contexte' }.freeze
REPLIE_SI_COUPE = <<~JS.freeze
  ((id) => {
    const texte = document.getElementById(id)
    const replie = texte.clientHeight
    texte.classList.remove('lire-plus--replie')
    const entier = texte.clientHeight
    texte.classList.add('lire-plus--replie')
    return { bouton: document.querySelector(`[aria-controls='${id}']`).checkVisibility(), revele: entier - replie }
  })(arguments[0])
JS

def replie_avec_le_bon_bouton?(etat) = etat['replie'] && etat['bouton'] == 'Lire plus : Contexte'

def attendre_le_repli(page)
  etat = nil
  Timeout.timeout(5) { sleep 0.1 until replie_avec_le_bon_bouton?(etat = etat_lire_plus(page, 'contexte-texte')) }
  sleep 0.3
  etat
end

def titre_en_vue?(position) = position['haut'].between?(position['sous'], position['fenetre'])

def replier_depuis_le_bas(page, etape)
  avant = haut_de_section(page, 'Contexte')
  page.find_button('Lire moins : Contexte').click
  etat = attendre_le_repli(page)
  apres = haut_de_section(page, 'Contexte')
  raise "titre Contexte hors de vue après « Lire moins » : avant #{avant} après #{apres}" unless titre_en_vue?(apres)

  Verify.evidence(DOSSIER, page, etape, "titre_avant_clic=#{avant['haut']} titre_apres=#{apres['haut']} sous=#{apres['sous']} " \
                                        "fenetre=#{apres['fenetre']} #{etat}")
end

def bouton_sans_texte_a_reveler(page, demarche, id)
  return unless page.has_css?("##{id}.lire-plus--replie", wait: 10)

  sleep 0.3
  etat = page.evaluate_script(REPLIE_SI_COUPE, id)
  "#{demarche.slug}##{id} #{etat}" if etat['bouton'] != etat['revele'].positive?
end

def lire_plus_seuil(page)
  faux = Demarche.visibles.flat_map do |demarche|
    page.visit("/demarches/#{demarche.slug}")
    %w[contexte-texte cadre-juridique-texte].filter_map { bouton_sans_texte_a_reveler(page, demarche, it) }
  end
  raise "bouton sans texte à révéler (ou l'inverse) : #{faux.join(' ; ')}" if faux.any?

  Verify.evidence(DOSSIER, page, 'seuil', "#{Demarche.visibles.count} cas d'usage : bouton si et seulement si le dépliage révèle du texte")
end

def lire_plus_sans_js(demarche)
  page = Verify.session(javascript: false)
  page.visit("/demarches/#{demarche.slug}")
  texte = page.find('#contexte-texte')
  raise 'replié sans JS' if texte[:class].to_s.include?('lire-plus--replie')
  raise 'bouton affiché sans JS' if page.has_button?('Lire plus : Contexte', wait: 0)

  Verify.evidence(DOSSIER, page, 'sans-js', "classe=#{texte[:class].inspect} bouton=masque caracteres=#{texte.text.size}")
ensure
  page&.quit
end

def replie_a_l_arrivee(page, long)
  page.current_window.resize_to(1280, 1024)
  page.visit("/demarches/#{long.slug}")
  replie = attendre_lire_plus(page, 'contexte-texte', CONTEXTE_REPLIE.merge('expanded' => 'false', 'lien' => true, 'fondu' => true, 'fleche' => 'down'))
  Verify.evidence(DOSSIER, page, 'replie', "slug=#{long.slug} #{replie}")
  replie
end

def deplier_puis_replier(page, replie)
  page.find_button('Lire plus : Contexte').click
  deplie = attendre_lire_plus(page, 'contexte-texte', CONTEXTE_DEPLIE.merge('coupe' => false, 'expanded' => 'true', 'fondu' => false, 'fleche' => 'up'))
  raise "déplié moins haut que replié #{deplie}" unless deplie['hauteur'] > replie['hauteur']

  Verify.evidence(DOSSIER, page, 'deplie', deplie.to_s)
  replier_depuis_le_bas(page, 'repli')
end

def deplie_au_focus(page)
  page.execute_script("[...document.querySelectorAll('#contexte-texte a')].at(-1).focus()")
  Verify.evidence(DOSSIER, page, 'focus-lien', attendre_lire_plus(page, 'contexte-texte', CONTEXTE_DEPLIE.merge('expanded' => 'true')).to_s)
end

def sur_telephone(page, long)
  page.current_window.resize_to(375, 800)
  page.visit("/demarches/#{long.slug}")
  Verify.evidence(DOSSIER, page, 'mobile', attendre_lire_plus(page, 'contexte-texte', CONTEXTE_REPLIE.merge('fondu' => true)).to_s)
  page.find_button('Lire plus : Contexte').click
  attendre_lire_plus(page, 'contexte-texte', CONTEXTE_DEPLIE)
  replier_depuis_le_bas(page, 'mobile-repli')
end

def texte_court(page, court)
  entier = { 'coupe' => false, 'bouton' => nil, 'fondu' => false }
  page.visit("/demarches/#{court.slug}")
  Verify.evidence(DOSSIER, page, 'mobile-court', attendre_lire_plus(page, 'cadre-juridique-texte', entier).to_s)
  page.current_window.resize_to(1280, 1024)
  page.visit("/demarches/#{court.slug}")
  Verify.evidence(DOSSIER, page, 'court', "slug=#{court.slug} #{attendre_lire_plus(page, 'cadre-juridique-texte', entier.merge('replie' => true))}")
end

Verify.drive(__FILE__) do |page|
  long = Demarche.visibles.max_by { it.contexte.to_s.size }
  court = Demarche.visibles.select { it.cadre_juridique.present? }.min_by { it.cadre_juridique.size }
  replie = Verify.check('Folded') { replie_a_l_arrivee(page, long) }
  Verify.check('Toggle') { deplier_puis_replier(page, replie) }
  Verify.check('Focus') { deplie_au_focus(page) }
  Verify.check('Mobile') { sur_telephone(page, long) }
  Verify.check('Short') { texte_court(page, court) }
  Verify.check('Threshold') { lire_plus_seuil(page) }
  Verify.check('No JS') do
    page.quit
    lire_plus_sans_js(long)
  end
end
