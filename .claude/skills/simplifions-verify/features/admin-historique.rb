require_relative '../harness'

DOSSIER = 'admin-historique'.freeze
ADMIN_EMAIL = Verify::ADMIN[:email]

def evenements(demarche) = ActiveRecord::Base.uncached { demarche.versions.reload.map(&:event) }

def premiere_version_de_l_onglet(page, demarche, nom, (etape, titre))
  Verify.onglet(page, 'Historique')
  version = page.first('#onglet-historique-panneau section')
  titre_lu = version.find('h2').text
  ligne = version.first('tbody tr').all('th, td').map(&:text)
  raise "#{etape} : titre #{titre_lu}" unless titre_lu.start_with?("#{titre} par #{ADMIN_EMAIL} le ")
  raise "#{etape} : ligne #{ligne}" unless ligne == ['Nom', nom, "#{nom} brouillon"]

  Verify.evidence(DOSSIER, page, etape, "titre=#{titre_lu} ligne=#{ligne} evenements=#{evenements(demarche)}")
  Verify.onglet(page, 'Fiche')
end

def creee_par_l_import(page, nom)
  demarche = PaperTrail.request(whodunnit: 'Import Grist') { Demarche.create!(nom:) }
  Verify.ouvrir_fiche(page, nom)
  page.assert_selector 'aside.admin-panneau', text: /Créée par Import Grist le/
  Verify.evidence(DOSSIER, page, 'creee', "colonne=#{page.find('aside.admin-panneau').text.lines.grep(/par/).first&.strip}")
  demarche
end

def renommee_par_l_admin(page, demarche, renommee)
  page.fill_in 'Nom', with: renommee
  page.click_button 'Enregistrer'
  page.assert_text "« #{renommee} » enregistré."
  page.assert_selector 'aside.admin-panneau', text: /Modifiée par #{ADMIN_EMAIL} le/
  auteurs = ActiveRecord::Base.uncached { demarche.versions.reload.map(&:whodunnit) }
  raise "auteurs #{auteurs}" unless auteurs == ['Import Grist', Admin.find_by(email: ADMIN_EMAIL).id.to_s]

  Verify.evidence(DOSSIER, page, 'modifiee', "versions=#{auteurs}")
end

def titres_de_l_historique(page)
  titres = page.all('main section h2').map(&:text)
  attendus = ["Modification par #{ADMIN_EMAIL}", 'Création par Import Grist']
  raise "titres #{titres}" unless titres.size == 2 && titres.zip(attendus).all? { |titre, debut| titre.start_with?(debut) }

  titres
end

def page_historique(page, demarche, nom, renommee)
  page.click_link 'Historique'
  page.assert_current_path("/admin/historique/demarches/#{demarche.id}")
  titres = titres_de_l_historique(page)
  ligne = page.first('main section tbody tr').all('th, td').map(&:text)
  raise "ligne #{ligne}" unless ligne == ['Nom', nom, renommee]

  Verify.evidence(DOSSIER, page, 'page', "titres=#{titres} premiere_ligne=#{ligne}")
end

def historique_mobile(page)
  page.current_window.resize_to(375, 800)
  debord = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')
  raise "375 px : débord #{debord}" if debord.positive?

  Verify.evidence(DOSSIER, page, 'mobile', "debord=#{debord}")
  page.current_window.resize_to(1280, 1024)
end

def retour_a_la_fiche(page, renommee)
  page.click_link 'Retour à la fiche'
  page.find_field('Nom', with: renommee)
  Verify.evidence(DOSSIER, page, 'retour', "chemin=#{page.current_path}")
end

def brouillon(page, demarche, nom)
  demarche.update!(slug: "verif-verify-map-historique-#{Verify.browser}", visible: true)
  page.refresh
  page.fill_in 'Nom', with: "#{nom} brouillon"
  page.click_button 'Enregistrer'
  page.assert_text 'brouillon enregistré'
  premiere_version_de_l_onglet(page, demarche, nom, ['brouillon', 'Modification en brouillon'])
end

def publication(page, demarche, nom)
  page.click_button 'Publier'
  page.assert_text "« #{nom} brouillon » enregistré."
  premiere_version_de_l_onglet(page, demarche, nom, ['publication', 'Publication du brouillon'])
end

def abandon(page, demarche, nom)
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.accept_confirm { page.click_button 'Abandonner le brouillon' }
  page.assert_text 'abandonné'
  premiere_version_de_l_onglet(page, demarche, nom, ['abandon', 'Abandon du brouillon'])
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  renommee = "#{nom} renommée"
  Verify.login(page)
  demarche = Verify.check('Created') { creee_par_l_import(page, nom) }
  Verify.check('Updated') { renommee_par_l_admin(page, demarche, renommee) }
  Verify.check('History') { page_historique(page, demarche, nom, renommee) }
  Verify.check('Mobile') { historique_mobile(page) }
  Verify.check('Back') { retour_a_la_fiche(page, renommee) }
  Verify.check('Draft') { brouillon(page, demarche, renommee) }
  Verify.check('Publication') { publication(page, demarche, renommee) }
  Verify.check('Abandon') { abandon(page, demarche, renommee) }
  Verify.check('Proof') { raise "événements #{evenements(demarche)}" unless evenements(demarche).last(4) == %w[brouillon publication brouillon abandon] }
ensure
  page.current_window.resize_to(1280, 1024)
  ids = Demarche.where('nom LIKE ?', "#{nom}%").ids
  Demarche.where(id: ids).destroy_all
  PaperTrail::Version.where(item_type: 'Demarche', item_id: ids).delete_all
end
