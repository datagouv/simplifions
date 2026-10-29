require_relative '../harness'

DOSSIER = 'clavier-lecteur-ecran'.freeze

def origine(page) = page.evaluate_script('performance.timeOrigin')

def element_actif(page)
  page.evaluate_script(<<~JS)
    (() => {
      const actif = document.activeElement
      return [(actif.labels?.[0] || actif).textContent.trim(), !!actif.closest('#content')]
    })()
  JS
end

def premier_tab(page)
  page.visit('/')
  debut = origine(page)
  page.find('body').send_keys(:tab)
  premier = element_actif(page)
  raise "premier Tab : #{premier}" unless premier == ['Contenu', false]

  Verify.evidence(DOSSIER, page, '1-premier-tab', "focus=#{premier.first}")
  debut
end

def entree_contenu(page, debut)
  page.send_keys(:enter)
  page.send_keys(:tab)
  suivant = element_actif(page)
  raise "après Contenu : #{suivant}, rechargée=#{origine(page) != debut}" unless suivant.last && origine(page) == debut

  hash = page.evaluate_script('location.hash')
  Verify.evidence(DOSSIER, page, '2-entree-contenu', "hash=#{hash} focus_suivant=#{suivant.first} dans_main=#{suivant.last}")
end

def fleches(page)
  page.visit('/demarches')
  debut = origine(page)
  usagers = page.find_field('Démarches à destination des :')
  usagers.send_keys(:down, :down, :down)
  choisi = usagers.value
  raise "flèches : valeur=#{choisi.inspect}, rechargée=#{origine(page) != debut}" if choisi.blank? || origine(page) != debut

  page.assert_current_path('/demarches')
  Verify.evidence(DOSSIER, page, '3-fleches-sans-rechargement', "valeur=#{choisi} meme_page=true")
  choisi
end

def appliquer(page, choisi)
  page.click_button 'Appliquer les filtres'
  page.assert_current_path(/target-users=#{choisi}/, url: false)
  Verify.evidence(DOSSIER, page, '4-appliquer', "url=#{page.current_url[/\?.*/]}")
end

def compteur(page) = page.find('[role=status]', text: 'disponible').text

def clavier_compteur(page)
  solution = Solution.visibles.where.not(slug: nil).find { it.integratrices_visibles.many? }
  page.visit("/solutions/#{solution.slug}")
  avant = compteur(page)
  page.find_field("Cas d'usage :").send_keys(:down)
  page.assert_no_selector('[role=status]', text: avant, exact_text: true)
  Verify.evidence(DOSSIER, page, '5-compteur', "slug=#{solution.slug} avant=#{avant} apres=#{compteur(page)}")
end

def champ_endpoints_deplie(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  champ = page.first('[data-endpoints-target=input]', visible: :all)
  repli = page.evaluate_script('arguments[0].closest(".fr-collapse")?.id', champ)
  page.find("[aria-controls='#{repli}']").click if repli
  champ
end

def annonce_endpoints(champ) = champ.find(:xpath, 'ancestor::*[@data-controller="endpoints"]').find('[role=status]', visible: :all)

def demarche_a_plusieurs_endpoints = Demarche.visibles.find { |d| d.recommandations.visibles.any? { it.apis_utiles.size > 1 } }

def clavier_endpoints(page)
  demarche = demarche_a_plusieurs_endpoints
  champ = champ_endpoints_deplie(page, demarche)
  annonce = annonce_endpoints(champ)
  raise "annonce au chargement : #{annonce.text(:all)}" unless annonce.text(:all).empty?

  champ.set('zzzz')
  page.assert_selector('[role=status]', text: '0 endpoint', visible: :all)
  Verify.evidence(DOSSIER, page, '6-endpoints', "slug=#{demarche.slug} annonce=#{annonce.text(:all)}")
end

def clavier_sirene(page)
  page.visit('/articles/qu-est-ce-qu-une-api')
  annonce = page.find('[data-controller=sirene-demo] [role=status]', visible: :all)
  page.fill_in "Numéro de SIRET d'un établissement :", with: '123'
  page.click_button "Interroger l'API"
  page.assert_selector('[data-controller=sirene-demo] [role=status]', text: '14 chiffres', visible: :all)
  erreur = annonce.text(:all)
  page.execute_script(<<~JS)
    window.fetch = () => Promise.resolve(new Response(JSON.stringify({ results: [{ nom_complet: 'Vérif Sirene', etat_administratif: 'A', siege: {} }] })))
  JS
  page.fill_in "Numéro de SIRET d'un établissement :", with: '35600000000048'
  page.click_button "Interroger l'API"
  page.assert_selector('[data-controller=sirene-demo] [role=status]', text: 'Résultat : Vérif Sirene', visible: :all)
  Verify.evidence(DOSSIER, page, '7-sirene', "erreur=#{erreur} resultat=#{annonce.text(:all)}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Contenu') { entree_contenu(page, premier_tab(page)) }
  Verify.check('Flèches') { appliquer(page, fleches(page)) }
  Verify.check('Compteur') { clavier_compteur(page) }
  Verify.check('Endpoints') { clavier_endpoints(page) }
  Verify.check('Sirene') { clavier_sirene(page) }
  Verify.check('Proof') { Verify.captures_presentes(DOSSIER, %w[1-premier-tab 2-entree-contenu 3-fleches-sans-rechargement 4-appliquer 5-compteur 6-endpoints 7-sirene]) }
end
