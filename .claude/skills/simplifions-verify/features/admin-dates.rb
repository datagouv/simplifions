require_relative '../harness'

DOSSIER = 'admin-dates'.freeze

def dates_de(demarche) = "demarche=#{demarche.id} cree_le=#{demarche.cree_le.iso8601(3)} modifie_le=#{demarche.modifie_le.iso8601(3)}"

def saisir_sans_dates(page, nom)
  page.visit('/admin/demarches/new')
  page.assert_no_selector "[name='demarche[cree_le]'], [name='demarche[modifie_le]']"
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
end

def creer(page, nom)
  saisir_sans_dates(page, nom)
  demarche = ActiveRecord::Base.uncached { Demarche.find_by!(nom:) }
  raise "dates a la creation #{demarche.cree_le.inspect} #{demarche.modifie_le.inspect}" unless demarche.cree_le&.after?(1.minute.ago) && demarche.modifie_le

  Verify.evidence(DOSSIER, page, 'cree', dates_de(demarche))
  demarche
end

def modifier(page, demarche, nom)
  creation = demarche.cree_le
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  demarche.reload
  raise "modification non datee #{demarche.modifie_le.inspect}" unless demarche.modifie_le > creation && demarche.cree_le == creation

  Verify.evidence(DOSSIER, page, 'modifie', dates_de(demarche))
end

def supprimer(page, demarche, nom)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  reste = ActiveRecord::Base.uncached { Demarche.where(id: demarche.id).count }
  raise "#{reste} ligne(s) restée(s) en base" unless reste.zero?

  Verify.evidence(DOSSIER, page, 'supprime', "reste_en_base=#{reste}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  demarche = Verify.check('Create') { creer(page, nom) }
  Verify.check('Edit') { modifier(page, demarche, "#{nom} modifiée") }
  Verify.check('Delete') { supprimer(page, demarche, "#{nom} modifiée") }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom: [nom, "#{nom} modifiée"]).destroy_all
end
