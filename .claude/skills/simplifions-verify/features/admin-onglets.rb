require_relative '../harness'

DOSSIER = 'admin-onglets'.freeze
ONGLETS = %w[Fiche Intégrations Recommandations Historique].freeze

def hauteur(page) = page.evaluate_script('document.documentElement.scrollHeight')

def onglet_retenu(page) = page.find('input[name=onglet]', visible: false).value

def quatre_onglets(page)
  page.visit('/admin/demarches/1/edit')
  libelles = page.all('[role=tab]').map(&:text)
  raise "onglets #{libelles}" unless libelles.map { it.split(' (').first } == ONGLETS

  libelles
end

def hauteurs_par_onglet(page)
  libelles = quatre_onglets(page)
  hauteurs = libelles.to_h { |libelle| Verify.onglet(page, libelle.split(' (').first).then { [libelle, hauteur(page)] } }
  Verify.evidence(DOSSIER, page, 'hauteurs-demarche-1', "hauteurs=#{hauteurs} recos_en_base=#{Demarche.find(1).recommandations.count}")
end

def fleche_droite(page)
  Verify.onglet(page, 'Fiche')
  page.find('[role=tab][aria-selected=true]').send_keys(:right)
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AIntégrations/
  raise "flèche : onglet retenu #{onglet_retenu(page)}" unless onglet_retenu(page) == 'integrations'
end

def demarche_et_integration(nom)
  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_1)
  [demarche, Integration.where(integree_id: api).order(:id).first]
end

def cocher_l_integration(page, cible)
  Verify.onglet(page, 'Intégrations')
  groupe = page.find('fieldset', text: 'Filtrer les intégrations')
  groupe.fill_in 'Filtrer les intégrations', with: I18n.transliterate(cible.libelle).scan(/[[:alnum:]]+/).join(' ')
  groupe.find("label[for=demarche_integration_ids_#{cible.id}]").click
  raise 'case cible non cochée' unless groupe.find("#demarche_integration_ids_#{cible.id}", visible: :all).checked?
end

def enregistrer_depuis_integrations(page, demarche, cible)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Nom', with: "#{demarche.nom} modifiée"
  cocher_l_integration(page, cible)
  page.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} modifiée » enregistré."
  page.assert_current_path(/onglet=integrations/, url: true)
  page.assert_selector '[role=tab][aria-selected=true]', text: 'Intégrations (1)'
end

def enregistre_en_base(page, demarche, cible)
  base = ActiveRecord::Base.uncached { Demarche.find(demarche.id).then { [it.nom, it.integration_ids] } }
  raise "enregistrement : base #{base}" unless base == ["#{demarche.nom} modifiée", [cible.id]]

  Verify.evidence(DOSSIER, page, 'enregistre-depuis-integrations', "url=#{page.current_url.split('/admin').last} base=#{base}")
end

def erreur_ouvre_fiche(page, demarche)
  Verify.onglet(page, 'Fiche')
  page.fill_in 'Nom', with: ''
  Verify.onglet(page, 'Historique')
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-alert--error', text: 'Nom doit être rempli'
  page.assert_selector '[role=tab][aria-selected=true]', text: 'Fiche'
  page.assert_selector '#demarche_nom', visible: true
  Verify.evidence(DOSSIER, page, 'erreur-ouvre-fiche', "onglet_ouvert=Fiche nom_en_base=#{ActiveRecord::Base.uncached { Demarche.find(demarche.id).nom }}")
end

def etroit(page, demarche)
  page.current_window.resize_to(375, 812)
  page.visit("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
  page.assert_selector '[role=tab][aria-selected=true]', text: /\ARecommandations/
  defilement = page.evaluate_script('document.documentElement.scrollWidth > innerWidth')
  raise 'défilement horizontal à 375 px' if defilement

  Verify.evidence(DOSSIER, page, 'etroit-375', "defilement_horizontal=#{defilement}")
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  demarche, cible = demarche_et_integration(nom)

  Verify.check('Démarche 1') { hauteurs_par_onglet(page).then { fleche_droite(page) } }
  Verify.check('Save from Intégrations') do
    enregistrer_depuis_integrations(page, demarche, cible)
    enregistre_en_base(page, demarche, cible)
  end
  Verify.check('Error opens Fiche') { erreur_ouvre_fiche(page, demarche) }
  Verify.check('375 px') { etroit(page, demarche) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  page.current_window.resize_to(1280, 1024)
  Demarche.where(nom: [nom, "#{nom} modifiée"]).destroy_all
end
