require_relative '../harness'

DOSSIER = 'admin-integrations-de-l-api'.freeze
INJECTER_UNE_DEMARCHE = <<~JS.freeze
  const c = document.createElement('input')
  c.type = 'hidden'
  c.name = 'integration[demarche_ids][]'
  c.value = arguments[0]
  document.getElementById('formulaire-fiche').append(c)
  c.dispatchEvent(new Event('change', { bubbles: true }))
JS

def cases_de(page, groupe) = page.all("input[type=checkbox][name$='[#{groupe}][]']", visible: :all)

def hors_regle(page, groupe)
  page.all("input[type=checkbox][name$='[#{groupe}][]'] + label", visible: :all).count { |l| l.text(:all).end_with?('(hors règle)') }
end

def lien_hors_regle(nom, integration)
  demarche = Demarche.create!(nom:)
  recommandation = Recommandation.create!(demarche:, solution_id: integration.integree_id, niveau: :niveau_1)
  demarche.integrations << integration
  Recommandation.where(id: recommandation.id).delete_all
  demarche
end

def cases_proposees(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  cases = cases_de(page, 'integration_ids').size
  raise "démarche 1 : #{cases} cases pour #{demarche.integrations_proposees.count} proposées" unless cases == demarche.integrations_proposees.count
  raise "démarche 1 : #{cases} cases, autant que d’intégrations" unless cases < Integration.count

  cases
end

def demarche_1(page)
  demarche = Demarche.find(1)
  cases = cases_proposees(page, demarche)
  marquees = hors_regle(page, 'integration_ids')
  hors = demarche.integrations.where.not(id: demarche.integrations_autorisees).count
  raise "démarche 1 : #{marquees} marquées hors règle pour #{hors}" unless marquees == hors

  Verify.evidence(DOSSIER, page, 'demarche-1', "cases=#{cases} avant=#{Integration.count} hors_regle=#{marquees}")
end

def integration_avec_lien_hors_regle(page, integration)
  page.visit("/admin/integrations/#{integration.id}/edit")
  cases = cases_de(page, 'demarche_ids').size
  raise "intégration : #{cases} cases pour #{integration.demarches_proposees.count}" unless cases == integration.demarches_proposees.count
  raise 'intégration : aucune démarche marquée hors règle' unless hors_regle(page, 'demarche_ids').positive?

  Verify.evidence(DOSSIER, page, 'integration', "integration=#{integration.id} cases=#{cases} hors_regle=#{hors_regle(page, 'demarche_ids')}")
end

def demarches_en_base(integration) = ActiveRecord::Base.uncached { Integration.find(integration.id).demarche_ids.sort }

def refus_serveur(page, integration)
  avant = demarches_en_base(integration)
  intrus = Demarche.where.not(id: integration.demarches_proposees).first!
  page.execute_script(INJECTER_UNE_DEMARCHE, intrus.id)
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-alert--error', text: "La démarche « #{intrus.nom} » ne recommande pas l’API ou le jeu de données intégré"
  apres = demarches_en_base(integration)
  raise "refus : base modifiée #{avant} → #{apres}" unless apres == avant

  Verify.evidence(DOSSIER, page, 'refus-serveur', "intrus=#{intrus.id} en_base_avant=#{avant.size} en_base_apres=#{apres.size}")
end

def nouvelle_integration(page)
  page.visit('/admin/integrations/new')
  raise 'nouvelle intégration : cases de démarches' unless cases_de(page, 'demarche_ids').empty?

  page.assert_text 'Démarches : à cocher une fois l’API ou le jeu de données enregistré'
  Verify.evidence(DOSSIER, page, 'nouvelle-integration', 'cases=0 message=affiché')
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  integration = Integration.order(:id).first
  lien_hors_regle(nom, integration)
  Verify.login(page)

  Verify.check('Démarche 1') { demarche_1(page) }
  Verify.check('Intégration') { integration_avec_lien_hors_regle(page, integration.reload) }
  Verify.check('Refus serveur') { refus_serveur(page, integration) }
  Verify.check('Nouvelle intégration') { nouvelle_integration(page) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Demarche.where(nom:).destroy_all
end
