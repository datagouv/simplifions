require_relative '../harness'

DOSSIER = 'admin-formulaire-modifie'.freeze
QUESTION = 'Quitter sans enregistrer les modifications ?'.freeze
BEFOREUNLOAD = "(() => { const e = new Event('beforeunload', { cancelable: true }); dispatchEvent(e); return e.defaultPrevented })()".freeze

def nom_en_base(demarche) = ActiveRecord::Base.uncached { Demarche.find(demarche.id).nom }
def demande(page, &) = Verify.demande_avant_de_partir(page, QUESTION, &)

def sans_saisie(page, nom)
  Verify.ouvrir_fiche(page, nom)
  page.click_link 'Annuler'
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence(DOSSIER, page, 'annuler-sans-saisie', 'confirmation=aucune')
end

def reste_sur_la_fiche(page, demarche, saisie)
  Verify.ouvrir_fiche(page, demarche.nom)
  page.fill_in 'Nom', with: saisie
  demande(page) { page.click_link 'Annuler' }
  demande(page) { page.go_back }
  demande(page) { page.click_button 'Supprimer' }
  page.find_field('Nom', with: saisie)
  raise 'démarche supprimée' unless Demarche.exists?(demarche.id)
end

def beforeunload(page, demarche)
  avertit = page.evaluate_script(BEFOREUNLOAD)
  raise 'beforeunload non bloqué' unless avertit

  Verify.evidence(DOSSIER, page, 'reste-sur-la-fiche',
    "url=#{page.current_path} champ=#{page.find_field('Nom').value} beforeunload_bloque=#{avertit} " \
    "en_base_apres_supprimer_refuse=#{Demarche.where(id: demarche.id).count}")
end

def supprimer_refuse_apres_depart(page)
  page.dismiss_confirm(/^Supprimer/) { page.accept_confirm(QUESTION) { page.click_button 'Supprimer' } }
  demande(page) { page.click_link 'Annuler' }
end

def quitter_la_fiche(page, demarche, saisie)
  page.fill_in 'Nom', with: saisie
  page.accept_confirm(QUESTION) { page.go_back }
  page.assert_selector 'h1', text: 'Démarches'
  raise "nom en base #{nom_en_base(demarche)}" unless nom_en_base(demarche) == demarche.nom
end

def reseau_coupe(page, demarche, saisie)
  page.execute_script("window.fetch = () => Promise.reject(new TypeError('réseau coupé'))")
  page.fill_in 'Nom', with: saisie
  page.click_button 'Enregistrer'
  demande(page) { page.click_link 'Annuler' }
  Verify.evidence(DOSSIER, page, 'reseau-coupe', "champ=#{page.find_field('Nom').value} confirmation=demandee")
  page.accept_confirm(QUESTION) { page.go_back }
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence(DOSSIER, page, 'quitte', "nom_en_base=#{nom_en_base(demarche)}")
end

def refus_422(page, nom)
  Verify.ouvrir_fiche(page, nom)
  page.fill_in 'Nom', with: ''
  page.click_button 'Enregistrer'
  page.assert_text 'Nom doit être rempli'
  demande(page) { page.click_link 'Annuler' }
end

def enregistrer(page, demarche, nom)
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  raise "nom en base #{nom_en_base(demarche)}" unless nom_en_base(demarche) == nom

  Verify.evidence(DOSSIER, page, 'enregistre', "confirmation=aucune nom_en_base=#{nom_en_base(demarche)}")
end

def supprimer(page, demarche, nom)
  Verify.ouvrir_fiche(page, nom)
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  reste = ActiveRecord::Base.uncached { Demarche.where(id: demarche.id).count }
  raise "#{reste} ligne(s) restée(s) en base" unless reste.zero?

  Verify.evidence(DOSSIER, page, 'supprime', "confirmation=suppression_seule en_base=#{reste}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  demarche = Demarche.create!(nom:)
  Verify.login(page)

  Verify.check('Unchanged') { sans_saisie(page, nom) }
  Verify.check('Changed, stay') { reste_sur_la_fiche(page, demarche, "#{nom} modifié") }
  Verify.check('beforeunload') { beforeunload(page, demarche) }
  Verify.check('Delete refused after leaving') { supprimer_refuse_apres_depart(page) }
  Verify.check('Changed, leave') { quitter_la_fiche(page, demarche, "#{nom} modifié encore") }
  Verify.check('Forward after leaving') { page.go_forward.then { page.find_field('Nom', with: nom) } }
  Verify.check('Network failure') { reseau_coupe(page, demarche, "#{nom} modifié") }
  Verify.check('422') { refus_422(page, nom) }
  Verify.check('Save') { enregistrer(page, demarche, "#{nom} enregistré") }
  Verify.check('Delete, unchanged') { supprimer(page, demarche, "#{nom} enregistré") }
  Verify.logout(page)
ensure
  Demarche.where(id: demarche&.id).destroy_all
end
