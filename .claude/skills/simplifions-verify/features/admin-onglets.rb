require_relative '../harness'

DOSSIER = 'admin-onglets'.freeze
ONGLETS = ['Fiche', 'API fournies', 'API intégrées', 'Solutions qui l’intègrent', 'Recommandée dans', 'Historique'].freeze
ATTENTE_ENREGISTREMENT = 15

def onglet_retenu(page) = page.find('input[name=onglet]', visible: false).value

def demarche_sans_onglet(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector :button, 'Modifier le contexte'
  page.assert_no_selector '[role=tablist]'
  Verify.evidence(DOSSIER, page, 'demarche-sans-onglet', "onglets=#{page.all('[role=tab]').size}")
end

def onglets_de_la_solution(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  libelles = page.all('[role=tab]').map { it.text.split(' (').first }
  raise "onglets #{libelles}" unless libelles == ONGLETS

  page.find('[role=tab][aria-selected=true]').send_keys(:right)
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AAPI fournies/
  raise "flèche : onglet retenu #{onglet_retenu(page)}" unless onglet_retenu(page) == 'api-fournies'

  Verify.evidence(DOSSIER, page, 'onglets-solution', "onglets=#{libelles}")
end

def enregistrer_depuis_historique(page, solution)
  Verify.onglet(page, 'Fiche')
  page.fill_in 'Nom', with: "#{solution.nom} modifiée"
  Verify.onglet(page, 'Historique')
  page.click_button 'Enregistrer'
  page.assert_text "« #{solution.nom} modifiée » enregistré.", wait: ATTENTE_ENREGISTREMENT
  page.assert_current_path(/onglet=historique/, url: true)
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AHistorique/
  lu = ActiveRecord::Base.uncached { Solution.find(solution.id).nom }
  raise "nom en base : #{lu}" unless lu == "#{solution.nom} modifiée"

  Verify.evidence(DOSSIER, page, 'enregistre-depuis-historique', "url=#{page.current_url.split('/admin').last} nom=#{lu}")
end

def erreur_ouvre_fiche(page, solution)
  Verify.onglet(page, 'Fiche')
  page.fill_in 'Nom', with: ''
  Verify.onglet(page, 'Historique')
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-input-group--error', text: 'doit être rempli', wait: ATTENTE_ENREGISTREMENT
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AFiche/
  Verify.evidence(DOSSIER, page, 'erreur-ouvre-fiche', "onglet_ouvert=Fiche nom_en_base=#{ActiveRecord::Base.uncached { Solution.find(solution.id).nom }}")
end

def etroit(page, solution)
  page.current_window.resize_to(375, 812)
  page.visit("/admin/solutions/#{solution.id}/edit?onglet=historique")
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AHistorique/
  defilement = page.evaluate_script('document.documentElement.scrollWidth > innerWidth')
  raise 'défilement horizontal à 375 px' if defilement

  Verify.evidence(DOSSIER, page, 'etroit-375', "defilement_horizontal=#{defilement}")
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  demarche = Demarche.create!(nom:)
  solution = Solution.create!(nom:)

  Verify.check('Démarche without tabs') { demarche_sans_onglet(page, demarche) }
  Verify.check('Solution tabs') { onglets_de_la_solution(page, solution) }
  Verify.check('Save from Historique') { enregistrer_depuis_historique(page, solution) }
  Verify.check('Error opens Fiche') { erreur_ouvre_fiche(page, solution) }
  Verify.check('375 px') { etroit(page, solution) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  page.current_window.resize_to(1280, 1024)
  Demarche.where(nom:).destroy_all
  Solution.where(nom: [nom, "#{nom} modifiée"]).destroy_all
end
