require_relative '../harness'

DOSSIER = 'admin-vocabulaires'.freeze

def ajouter(page, nom, slug)
  page.click_link 'Ajouter'
  page.fill_in 'Nom', with: nom
  page.fill_in 'Slug', with: slug
  page.select 'Usager', from: 'Catégorie'
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  Vocabulaire.find_by!(nom:).tap do |ligne|
    page.assert_current_path("/admin/vocabulaires/#{ligne.id}")
    page.assert_selector 'h1', text: nom
  end
end

def lecture_et_fil(page, nom, slug)
  lecture = page.all('dt').map { |terme| "#{terme.text}=#{terme.find(:xpath, 'following-sibling::dd[1]').text}" }
  raise "lecture #{lecture}" unless lecture.first(2) == ["Slug=#{slug}", 'Catégorie=Usager']

  fil = page.all('.fr-breadcrumb__list li', visible: :all).map { |etape| etape.text(:all).strip }
  raise "fil #{fil}" unless fil == ['Administration', 'Vocabulaires', nom]

  "lecture=#{lecture.join(' | ')} fil=#{fil.join(' > ')}"
end

def renommer(page, ancien, nouveau)
  page.click_link 'Modifier'
  page.fill_in 'Nom', with: nouveau
  page.click_button 'Enregistrer'
  page.assert_text "« #{nouveau} » enregistré."
  page.assert_selector 'h1', text: nouveau unless nouveau == ancien
end

def supprimer(page, nom)
  Verify.rubrique(page, 'Vocabulaires')
  page.assert_no_selector :button, 'Supprimer'
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.click_link 'Modifier'
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  page.assert_no_selector 'td', text: nom
end

def prouver_la_suppression(page, nom)
  reste = ActiveRecord::Base.uncached { Vocabulaire.where(nom:).count }
  raise "#{reste} ligne(s) restée(s) en base" unless reste.zero?

  Verify.evidence(DOSSIER, page, 'supprime', "reste_en_base=#{reste}")
  Verify.logout(page)
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"

  Verify.check('Reach the table') do
    Verify.login(page)
    Verify.rubrique(page, 'Vocabulaires')
    page.assert_selector 'h1', text: 'Vocabulaires'
  end

  ligne = Verify.check('Add') do
    ajouter(page, nom, slug).tap do |cree|
      Verify.evidence(DOSSIER, page, 'cree',
        "id=#{cree.id} nom=#{cree.nom} categorie=#{cree.categorie} url=#{page.current_path} #{lecture_et_fil(page, nom, slug)} onglet=#{page.title}")
    end
  end

  Verify.check('Read back') { raise "catégorie #{ligne.categorie}" unless ligne.categorie == 'usager' }

  Verify.check('Rename') do
    renommer(page, nom, "#{nom} modifié")
    Verify.evidence(DOSSIER, page, 'modifie', "url=#{page.current_path} nom_en_base=#{ActiveRecord::Base.uncached { ligne.reload.nom }} onglet=#{page.title}")
    renommer(page, "#{nom} modifié", nom)
  end

  Verify.check('Delete') { supprimer(page, nom) }

  Verify.check('Proof') { prouver_la_suppression(page, nom) }
ensure
  Vocabulaire.where(nom: [nom, "#{nom} modifié"]).destroy_all
end
