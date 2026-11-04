require_relative '../harness'

EVENEMENTS_AVIS = <<~JS.freeze
  performance.getEntriesByType('resource').map(e => e.name).filter(n => n.includes('matomo.php') && n.includes('e_a='))
    .map(n => { const p = new URL(n).searchParams; return [p.get('e_c'), p.get('e_a'), p.get('e_n')].join(' | ') })
    .filter(e => e.startsWith('Avis sur la page'))
JS

def avis(page) = page.evaluate_script(EVENEMENTS_AVIS)

def bloc_avis(page) = page.find('[data-controller="avis-page"]')

def attendre_avis(page, attendu)
  fin = Time.current + 10
  sleep 0.1 until avis(page).include?(attendu) || Time.current > fin
  raise "pas d'évènement « #{attendu} », vus : #{avis(page)}" unless avis(page) == [attendu]
end

def lecture_comptee?(page) = page.evaluate_script(<<~JS)
  performance.getEntriesByType('resource').some(e => e.name.includes('matomo.php') && new URL(e.name).searchParams.get('e_c') === 'Lecture')
JS

def voter(page, choix, nom, moment = 'avant lecture')
  bloc = bloc_avis(page)
  bloc.scroll_to(bloc)
  Verify.evidence('avis-page', page, "#{nom.parameterize.first(30)}-avant")
  bloc.choose choix, allow_label_click: true
  bloc.click_button 'Envoyer mon avis'
  attendre_avis(page, "Avis sur la page | Trouver la page utile | #{choix} (#{moment}) — #{nom}")
  bloc.assert_text "Merci pour votre avis ! Vous avez répondu « #{choix} »."
  raise "le focus n'est pas sur le remerciement" unless page.evaluate_script('document.activeElement.textContent').include?('Merci')

  Verify.evidence('avis-page', page, "#{nom.parameterize.first(30)}-#{choix.parameterize}", avis(page).join(' ; '))
  bloc
end

def lien_de_retour(bloc) = bloc.all(:link, 'Dites-nous ce qui manque').first&.[]('href')

def sans_choix(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  bloc = bloc_avis(page)
  raise 'Envoyer mon avis actif sans choix' unless bloc.has_button?('Envoyer mon avis', disabled: true)

  bloc.choose 'Moyennement', allow_label_click: true
  raise 'Envoyer mon avis reste désactivé après un choix' unless bloc.has_button?('Envoyer mon avis', disabled: false)
  raise "évènement envoyé au simple choix : #{avis(page)}" if avis(page).any?

  Verify.evidence('avis-page', page, 'sans-choix', 'bouton désactivé, puis actif après un choix, aucun évènement')
end

def vote_demarche(page, demarche)
  bloc = voter(page, 'Non', "Démarche : #{demarche.nom}")
  attendu = "/contact/donner-son-avis?demarche=#{demarche.slug}"
  raise "lien de retour : #{lien_de_retour(bloc).inspect}" unless lien_de_retour(bloc)&.end_with?(attendu)
  raise 'lien Écrivez-nous affiché après Non' if bloc.has_link?('Écrivez-nous', wait: 0)
end

def vote_unique(page)
  bloc = bloc_avis(page)
  raise 'bouton Envoyer encore affiché' if bloc.has_button?('Envoyer mon avis', wait: 0)
  raise 'choix encore modifiables' unless bloc.all('input[type=radio]', visible: :all).all?(&:disabled?)
end

def vote_solution(page, solution)
  page.visit("/solutions/#{solution.slug}")
  bloc = voter(page, 'Oui', "Solution : #{solution.nom}")
  raise 'lien « Dites-nous ce qui manque » affiché après Oui' if lien_de_retour(bloc)

  ecrire = bloc.all(:link, 'Écrivez-nous').first&.[]('href')
  raise "lien Écrivez-nous : #{ecrire.inspect}" unless ecrire&.end_with?("/contact/donner-son-avis?solution=#{solution.slug}")
end

def vote_article(page)
  article = Article.find('qu-est-ce-qu-une-api')
  page.visit("/articles/#{article.slug}")
  bloc = voter(page, 'Moyennement', "Article : #{article.h1}")
  raise "lien de retour : #{lien_de_retour(bloc).inspect}" unless lien_de_retour(bloc)&.end_with?("/contact/donner-son-avis?article=#{article.slug}")
end

def vote_apres_lecture(page)
  article = Article.find('qu-est-ce-qu-une-api')
  page.visit("/articles/#{article.slug}")
  page.find('body').send_keys(:end)
  depart = Time.current
  sleep 0.5 until lecture_comptee?(page) || Time.current > depart + 40
  raise 'pas de lecture comptée après 40 s' unless lecture_comptee?(page)

  voter(page, 'Oui', "Article : #{article.h1}", 'après lecture')
end

TITRE_DECOUVERT = <<~JS.freeze
  (() => { const titre = document.querySelector('#avis-bas h2'), r = titre.getBoundingClientRect();
    return titre.contains(document.elementFromPoint(r.left + 20, r.top + r.height / 2)) })()
JS

def renvoi_sommaire(page, chemin)
  page.visit(chemin)
  page.find('nav.fr-summary').click_link 'Donner votre avis sur cette page'
  fin = Time.current + 3
  sleep 0.1 until page.evaluate_script(TITRE_DECOUVERT) || Time.current > fin
  raise 'titre de l’avis caché ou hors écran après le renvoi' unless page.evaluate_script(TITRE_DECOUVERT)

  Verify.evidence('avis-page', page, "renvoi-#{chemin.split('/')[1]}", page.evaluate_script('location.hash'))
end

AXE = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js'.freeze

def violations_axe(page, zone)
  page.execute_script(<<~JS)
    window.__axe = null;
    const lancer = () => axe.run(document.querySelector('#{zone}'), { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'] } })
      .then(r => { window.__axe = r.violations.map(v => v.id + ' : ' + v.nodes.map(n => n.target.join(' ')).join(', ')) });
    if (window.axe) lancer(); else { const s = document.createElement('script'); s.src = '#{AXE}'; s.onload = lancer; document.head.appendChild(s); }
  JS
  fin = Time.current + 20
  sleep 0.2 until page.evaluate_script('window.__axe') || Time.current > fin
  page.evaluate_script('window.__axe') || raise('axe-core non chargé')
end

def axe(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  vues = { 'bloc' => violations_axe(page, '#avis-bas'), 'sommaire' => violations_axe(page, 'nav.fr-summary') }
  bloc = bloc_avis(page)
  bloc.choose 'Non', allow_label_click: true
  bloc.click_button 'Envoyer mon avis'
  vues['bloc après vote'] = violations_axe(page, '#avis-bas')
  page.visit("/contact/donner-son-avis?demarche=#{demarche.slug}")
  vues['contact'] = violations_axe(page, 'main')
  raise "violations : #{vues.reject { |_, v| v.empty? }}" if vues.values.any?(&:any?)

  Verify.evidence('avis-page', page, 'axe', "aucune violation WCAG 2.1 AA : #{vues.keys.join(', ')}")
end

def touches(page, *touches) = touches.each { page.driver.browser.switch_to.active_element.send_keys(it) }

def clavier(page, solution)
  page.visit("/solutions/#{solution.slug}")
  page.execute_script("document.getElementById('avis-bas-bad').focus()")
  touches(page, :arrow_right)
  raise 'la flèche ne choisit pas Moyennement' unless page.find('#avis-bas-medium', visible: :all).checked?

  touches(page, :tab)
  raise 'Tab ne mène pas à Envoyer mon avis' unless page.evaluate_script('document.activeElement.textContent') == 'Envoyer mon avis'

  touches(page, :enter)
  attendre_avis(page, "Avis sur la page | Trouver la page utile | Moyennement (avant lecture) — Solution : #{solution.nom}")
  annonce = page.evaluate_script('document.activeElement.innerText').squish
  raise "focus sur « #{annonce} »" unless annonce.start_with?('Merci pour votre avis ! Vous avez répondu « Moyennement ».')

  Verify.evidence('avis-page', page, 'clavier', annonce)
end

def mobile(page, demarche)
  page.current_window.resize_to(375, 800)
  page.visit("/demarches/#{demarche.slug}")
  bloc = bloc_avis(page)
  bloc.scroll_to(bloc)
  gauches = bloc.all('.fr-radio-rich').map { page.evaluate_script('arguments[0].getBoundingClientRect().left', it).round }
  raise "choix côte à côte, bords gauches : #{gauches}" unless gauches.uniq.size == 1

  Verify.evidence('avis-page', page, 'mobile', "bords gauches #{gauches.join(' / ')}")
  renvoi_sommaire(page, "/demarches/#{demarche.slug}")
ensure
  page.current_window.resize_to(1280, 900)
end

Verify.drive(__FILE__) do |page|
  site_id = ENV.fetch('MATOMO_SITE_ID', nil)
  ENV['MATOMO_SITE_ID'] = '999999'
  demarche = Demarche.visibles.order(:nom).first
  solution = Solution.visibles.fiches.order(:nom).first

  Verify.check('Sans choix') { sans_choix(page, demarche) }
  Verify.check('Vote démarche') { vote_demarche(page, demarche) }
  Verify.check('Vote unique') { vote_unique(page) }
  Verify.check('Vote solution') { vote_solution(page, solution) }
  Verify.check('Vote article') { vote_article(page) }
  Verify.check('Vote après lecture') { vote_apres_lecture(page) }
  Verify.check('Clavier') { clavier(page, solution) }
  Verify.check('Axe') { axe(page, demarche) }
  Verify.check('Renvoi sommaire') do
    renvoi_sommaire(page, "/demarches/#{demarche.slug}")
    renvoi_sommaire(page, "/solutions/#{solution.slug}")
  end
  Verify.check('Mobile') { mobile(page, demarche) }
ensure
  ENV['MATOMO_SITE_ID'] = site_id
end
