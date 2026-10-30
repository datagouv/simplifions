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

LU_ET_VU = <<~JS.freeze
  (noeud => {
    const copie = noeud.cloneNode(true)
    copie.querySelectorAll('[aria-hidden=true]').forEach(cache => cache.remove())
    return [copie.textContent.replace(/\\s+/g, ' ').trim(), noeud.querySelector('[aria-hidden=true]')?.textContent]
  })(arguments[0])
JS

def lu_et_vu(page, selecteur, **) = page.evaluate_script(LU_ET_VU, page.find(selecteur, visible: :all, match: :first, **))

def muette?((lu, vu), icone) = vu == icone && lu.exclude?(icone)

def icone_du_titre(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  raise "<title> : #{page.title}" if page.title.include?(demarche.icone)

  titres = [lu_et_vu(page, 'h1'), lu_et_vu(page, '.fr-breadcrumb [aria-current=page]')]
  raise "titre et fil : #{titres}" unless titres.all? { it == [demarche.nom, demarche.icone] }

  "title=#{page.title} titre_lu=#{titres.first.first}"
end

def stylo_et_ampoule(page)
  stylo = lu_et_vu(page, '#titre-proposer-modification')
  ampoule = lu_et_vu(page, '.fr-highlight p', text: '💡')
  raise "✒️ #{stylo} 💡 #{ampoule}" unless muette?(stylo, '✒️') && muette?(ampoule, '💡')

  "stylo_lu=#{stylo.first}"
end

def icone_de_la_carte(page, demarche)
  page.visit("/demarches?q=#{CGI.escape(demarche.nom)}")
  carte = lu_et_vu(page, '.demarche-card h3 a', text: demarche.nom)
  raise "carte : #{carte}" unless carte == [demarche.nom, demarche.icone]

  "carte_lue=#{carte.first}"
end

def emoji_muets(page)
  demarche = Demarche.visibles.where.not(icone: [nil, '']).find { it.integratrices_par_categorie.key?(:site_de_consultation) }
  fiche = "#{icone_du_titre(page, demarche)} #{stylo_et_ampoule(page)}"
  carte = icone_de_la_carte(page, demarche)
  Verify.evidence(DOSSIER, page, '8-emoji-muets', "slug=#{demarche.slug} #{fiche} #{carte}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Contenu') { entree_contenu(page, premier_tab(page)) }
  Verify.check('Flèches') { appliquer(page, fleches(page)) }
  Verify.check('Compteur') { clavier_compteur(page) }
  Verify.check('Endpoints') { clavier_endpoints(page) }
  Verify.check('Sirene') { clavier_sirene(page) }
  Verify.check('Emoji muets') { emoji_muets(page) }
  Verify.check('Proof') { Verify.captures_presentes(DOSSIER, %w[1-premier-tab 2-entree-contenu 3-fleches-sans-rechargement 4-appliquer 5-compteur 6-endpoints 7-sirene 8-emoji-muets]) }
end
