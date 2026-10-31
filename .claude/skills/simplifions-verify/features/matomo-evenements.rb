require_relative '../harness'

EVENEMENTS = <<~JS.freeze
  performance.getEntriesByType('resource').map(e => e.name).filter(n => n.includes('matomo.php') && n.includes('e_a='))
    .map(n => { const p = new URL(n).searchParams; return [p.get('e_c'), p.get('e_a'), p.get('e_n')].join(' | ') })
JS
ACCES_DIRECT = "Par l'API directement".freeze

def evenements(page) = page.evaluate_script(EVENEMENTS)
def vider(page) = page.execute_script('performance.clearResourceTimings()')
def matomo_present?(page) = page.evaluate_script('typeof window._paq !== "undefined"')

def attendre_evenement(page, attendu)
  fin = Time.current + 5
  until evenements(page).any? { it.include?(attendu) }
    raise "pas d'évènement « #{attendu} », vus : #{evenements(page)}" if Time.current > fin

    sleep 0.1
  end
  Verify.evidence('matomo-evenements', page, attendu.parameterize, evenements(page).join(' ; '))
end

def aucun_evenement_de(page, action)
  sleep 0.5
  vus = evenements(page).select { it.include?(action) }
  raise "évènement inattendu : #{vus}" if vus.any?
end

def demarche_avec_endpoints(page)
  Demarche.visibles.find do |demarche|
    page.visit("/demarches/#{demarche.slug}")
    page.all('[data-endpoints-target=row]', visible: :all).size > 4
  end || raise('aucune démarche avec plus de 4 endpoints')
end

def pagination(page)
  page.visit('/demarches')
  vider(page)
  page.click_link 'Page 2'
  page.assert_current_path(/page=2/, url: false)
  attendre_evenement(page, 'Changer de page | 2')
end

def filtres(page)
  vider(page)
  page.first('select[data-matomo-action="Choisir un filtre"]').all('option')[1].select_option
  attendre_evenement(page, 'Choisir un filtre')
  page.click_button 'Appliquer les filtres'
  attendre_evenement(page, 'Appliquer les filtres')
end

def defilement(page)
  page.visit('/')
  page.execute_script('window.scrollTo(0, document.documentElement.scrollHeight)')
  aucun_evenement_de(page, 'Défilement')
  page.execute_script('window.scrollTo(0, 0)')
  page.find('body').send_keys(:end)
  attendre_evenement(page, 'Atteindre 100 %')
end

def ouverture(page, carte)
  vider(page)
  bouton = carte.find_button(ACCES_DIRECT)
  bouton.click
  attendre_evenement(page, "Ouvrir l'accès direct")
  vider(page)
  bouton.click
  aucun_evenement_de(page, "Ouvrir l'accès direct")
  carte.assert_selector 'button[aria-expanded=false]', text: ACCES_DIRECT
  bouton.click
  carte.assert_selector 'button[aria-expanded=true]', text: ACCES_DIRECT
end

def endpoints(page, carte, demarche)
  vider(page)
  carte.click_link 'Page 2'
  attendre_evenement(page, "Changer de page d'endpoints")
  carte.fill_in 'Filtrer les endpoints', with: 'api'
  carte.click_button 'Filtrer'
  attendre_evenement(page, 'Filtrer les endpoints')
  attendre_evenement(page, "— #{demarche.nom}")
end

def affichage(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  page.execute_script('window.scrollTo(0, 800)')
  page.click_button 'Affichage personnalisé'
  attendre_evenement(page, "Rouvrir l'affichage personnalisé")
end

def sirene(page)
  page.visit('/articles/qu-est-ce-qu-une-api')
  page.find('[data-sirene-demo-target=input]').set('123')
  page.find('[data-sirene-demo-target=button]').click
  attendre_evenement(page, "Interroger l'API Sirene | SIRET invalide — ")
  raise 'le numéro saisi est parti dans Matomo' if evenements(page).any? { it.include?('123') }
end

def contact(page)
  page.visit('/contact/modifier-solution')
  page.find('select#solution').all('option')[1].select_option
  attendre_evenement(page, 'Choisir la solution à modifier')
end

def connexion_sans_matomo(page)
  page.visit('/admin/connexion')
  raise 'Matomo absent avant la connexion' unless matomo_present?(page)

  page.fill_in 'Adresse e-mail', with: Verify::ADMIN[:email]
  page.fill_in 'Mot de passe', with: Verify::ADMIN[:password]
  page.click_button 'Se connecter'
  page.assert_text 'Connecté.'
  raise 'Matomo chargé après la connexion' if matomo_present?(page)
end

def site_public_sans_matomo(page)
  page.find('footer').click_link 'Plan du site'
  page.assert_current_path('/sitemap')
  raise 'Matomo chargé sur le site public pour un admin' if matomo_present?(page)
end

def retour_de_matomo(page)
  Verify.logout(page)
  raise 'Matomo absent après la déconnexion' unless matomo_present?(page)

  vider(page)
  page.find('footer').click_link 'Plan du site'
  attendre_evenement(page, 'Aller vers une page | Plan du site')
end

def admin(page)
  connexion_sans_matomo(page)
  site_public_sans_matomo(page)
  retour_de_matomo(page)
end

Verify.drive(__FILE__) do |page|
  site_id = ENV.fetch('MATOMO_SITE_ID', nil)
  ENV['MATOMO_SITE_ID'] = '999999'

  Verify.check('Pagination') { pagination(page) }
  Verify.check('Filtres') { filtres(page) }
  Verify.check('Défilement') { defilement(page) }
  demarche = demarche_avec_endpoints(page)
  carte = page.first('.reco-card:has([data-endpoints-target=row] ~ [data-endpoints-target=row])')
  Verify.check('Ouverture') { ouverture(page, carte) }
  Verify.check('Endpoints') { endpoints(page, carte, demarche) }
  Verify.check('Affichage') { affichage(page, demarche) }
  Verify.check('Sirene') { sirene(page) }
  Verify.check('Contact') { contact(page) }
  Verify.check('Admin') { admin(page) }
ensure
  ENV['MATOMO_SITE_ID'] = site_id
  Verify.remove_admin
end
