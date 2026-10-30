require_relative '../harness'

def hits_matomo(page, attendus)
  script = "performance.getEntriesByType('resource').map(e => e.name).filter(n => n.includes('matomo.php'))"
  Timeout.timeout(10) { sleep 0.2 until page.evaluate_script(script).size >= attendus }
  sleep 1
  page.evaluate_script(script).map { |url| Rack::Utils.parse_query(URI(url).query).slice('url', 'action_name', 'search', 'search_cat', 'search_count', 'urlref', 'link', 'download') }
end

def mesure_matomo(page, etape, attendus)
  hits = hits_matomo(page, attendus)
  raise "#{etape} : #{hits.size} hits, attendu #{attendus}" unless hits.size == attendus

  Verify.evidence('matomo', page, etape, hits.last.inspect)
  hits.last
end

def recherche_matomo(page, mot_cle, etape, attendus)
  page.fill_in 'Rechercher', with: mot_cle
  page.click_button 'Rechercher'
  page.assert_current_path(/q=#{CGI.escape(mot_cle)}&/, url: false)
  mesure_matomo(page, etape, attendus)
end

def clic_matomo(page, lien, etape, attendus)
  page.execute_script("addEventListener('click', e => e.preventDefault(), { once: true })")
  lien.click
  mesure_matomo(page, etape, attendus)
end

def lien_data_gouv(page) = page.find('footer a[href="https://data.gouv.fr"]')

def chargement(page)
  page.visit('/demarches')
  premier = mesure_matomo(page, '1-chargement', 1)
  raise "chargement : #{premier}" unless premier['action_name'].start_with?("Cas d'usages") && !premier.key?('search')
end

def premiere_recherche(page)
  recherche = recherche_matomo(page, 'eaje', '2-recherche', 2)
  attendu = { 'search' => 'eaje', 'search_cat' => "Cas d'usages", 'search_count' => Demarche.catalogue({ 'q' => 'eaje' }).count.to_s,
              'url' => page.current_url.split('?').first }
  raise "recherche : #{recherche}" unless recherche.slice(*attendu.keys) == attendu

  page.current_url
end

def ouvrir_un_resultat(page, page_de_recherche)
  page.first('a[href^="/demarches/"]').click
  page.assert_no_current_path(/q=eaje/, url: false)
  fiche = mesure_matomo(page, '3-clic-resultat', 3)
  raise "fiche : #{fiche}" unless fiche['url'] == page.current_url && fiche['action_name'] == page.title && !fiche.key?('search')
  raise "référent de la fiche : #{fiche['urlref']}, attendu #{page_de_recherche}" unless fiche['urlref'] == page_de_recherche
end

def retour(page, chemin, etape, attendus)
  page.go_back
  page.assert_current_path(chemin, url: false)
  hit = mesure_matomo(page, etape, attendus)
  raise "#{etape} compté comme recherche : #{hit}" if hit.key?('search')
end

def recherche_non_comptee(page, mot_cle, etape, attendus)
  hit = recherche_matomo(page, mot_cle, etape, attendus)
  raise "#{etape} compté comme recherche : #{hit}" if hit.key?('search')
end

def autre_recherche(page)
  autre = recherche_matomo(page, 'api', '6-autre-recherche', 6)
  raise "autre recherche : #{autre}" unless autre['search'] == 'api'
end

def lien_sortant(page, etape, attendus, &clic)
  hit = clic ? clic.call.then { mesure_matomo(page, etape, attendus) } : clic_matomo(page, lien_data_gouv(page), etape, attendus)
  raise "#{etape} : #{hit}" unless hit['link'] == 'https://data.gouv.fr/'
end

def telechargement(page)
  page.execute_script("document.querySelector('main').insertAdjacentHTML('beforeend', '<a href=\"/guide.pdf\">Guide de vérif</a>')")
  hit = clic_matomo(page, page.find_link('Guide de vérif'), '10-telechargement-apres-navigation', 10)
  raise "téléchargement : #{hit}" unless hit['download'].to_s.end_with?('/guide.pdf') && !hit.key?('link')
end

def clic_molette(page)
  page.execute_script("addEventListener('auxclick', e => e.preventDefault(), { once: true })")
  page.driver.browser.action.move_to(lien_data_gouv(page).native).pointer_down(:middle).pointer_up(:middle).perform
end

def clic_droit(page)
  page.execute_script("addEventListener('contextmenu', e => e.preventDefault(), { once: true })")
  lien_data_gouv(page).right_click
end

Verify.drive(__FILE__) do |page|
  site_id = ENV.fetch('MATOMO_SITE_ID', nil)
  ENV['MATOMO_SITE_ID'] = '999999'

  Verify.check('Load') { chargement(page) }
  page_de_recherche = Verify.check('Search') { premiere_recherche(page) }
  Verify.check('Open a result') { ouvrir_un_resultat(page, page_de_recherche) }
  Verify.check('Back') { retour(page, /q=eaje/, '4-retour', 4) }
  Verify.check('Same search again') { recherche_non_comptee(page, 'eaje', '5-meme-recherche', 5) }
  Verify.check('Another search') { autre_recherche(page) }
  Verify.check('Back to the older search') { retour(page, /q=eaje&/, '7-retour-recherche-precedente', 7) }
  Verify.check('One character') { recherche_non_comptee(page, 'e', '8-mot-cle-court', 8) }
  Verify.check('Outlink after navigation') { lien_sortant(page, '9-lien-sortant-apres-navigation', 9) }
  Verify.check('Download after navigation') { telechargement(page) }
  Verify.check('Outlink on the first page') do
    page.visit('/demarches')
    mesure_matomo(page, '11-premiere-page', 1)
    lien_sortant(page, '11-lien-sortant-premiere-page', 2)
  end
  Verify.check('Middle click') { lien_sortant(page, '12-clic-molette', 3) { clic_molette(page) } }
  Verify.check('Right click') { lien_sortant(page, '13-clic-droit', 4) { clic_droit(page) } }
  Verify.check('Proof') { Verify.captures_presentes('matomo', %w[1-chargement 6-autre-recherche 13-clic-droit]) }
ensure
  ENV['MATOMO_SITE_ID'] = site_id
end
