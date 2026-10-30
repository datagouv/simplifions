require_relative '../harness'

DOSSIER = 'admin-supprimer-demarche'.freeze

def atteindre_la_table(page, demarche, solution)
  Verify.login(page)
  Verify.rubrique(page, 'Démarches')
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence(DOSSIER, page, 'avant', "demarche=#{demarche.id} recommandations=#{Recommandation.where(demarche:).count} solution=#{solution.id}")
end

def supprimer(page, nom)
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.accept_confirm("Supprimer « #{nom} » ? 1 recommandation sera supprimée.") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  page.assert_no_selector 'td', text: nom
end

def relire(page, demarche, solution)
  lu = ActiveRecord::Base.uncached do
    [Demarche.where(id: demarche.id).count, Recommandation.where(demarche:).count, Solution.where(id: solution.id).count]
  end
  raise "démarche, recommandations, solution en base : #{lu}" unless lu == [0, 0, 1]

  Verify.evidence(DOSSIER, page, 'apres', "demarche_en_base=#{lu[0]} recommandations=#{lu[1]} solution_en_base=#{lu[2]}")
end

def confirmation_annulee(page, organisation)
  privees = organisation.solutions_rendues_privees.map(&:libelle_admin)
  page.visit("/admin/organisations/#{organisation.id}/edit")
  message = page.dismiss_confirm { page.click_button 'Supprimer' }
  raise "confirmation #{message}" unless privees.all? { |libelle| message.include?(libelle) }

  "privees=#{privees.size} confirmation=#{message}"
end

def organisation_annulee(page)
  organisation = Organisation.order(:id).find { |o| o.solutions_rendues_privees.exists? }
  confirmation = confirmation_annulee(page, organisation)
  en_base = ActiveRecord::Base.uncached { Organisation.where(id: organisation.id).count }
  raise 'organisation supprimée' unless en_base == 1

  Verify.evidence(DOSSIER, page, 'organisation-annulee', "organisation=#{organisation.id} en_base=#{en_base} #{confirmation}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  solution = Solution.order(:id).find { |s| !s.privee? }
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution:, niveau: :niveau_1)

  Verify.check('Reach the table') { atteindre_la_table(page, demarche, solution) }
  Verify.check('Delete') { supprimer(page, nom) }
  Verify.check('Read back') { relire(page, demarche, solution) }
  Verify.check('Organisation, cancelled') { organisation_annulee(page) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom:).destroy_all
end
