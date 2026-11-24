require_relative '../harness'

DOSSIER = 'admin-fiche-demarche'.freeze
QUESTION = 'Quitter sans enregistrer les modifications ?'.freeze

def lu(demarche) = ActiveRecord::Base.uncached { Demarche.find(demarche.id) }

def atteindre(page, nom)
  Verify.login(page)
  Verify.rubrique(page, 'Démarches')
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.assert_selector 'h1', text: nom
  page.assert_selector 'aside.admin-panneau', text: 'État et actions'
  page.assert_selector :field, 'Contexte'
end

def enregistrer_un_champ(page, demarche)
  Verify.modifier_la_fiche(page, 'Contexte' => 'Contexte modifié par la vérif')
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_selector :field, 'Contexte', with: 'Contexte modifié par la vérif'
  contexte = lu(demarche).contexte
  raise "contexte en base : #{contexte}" unless contexte == 'Contexte modifié par la vérif'

  page.scroll_to(page.find_field('Contexte'), align: :center)
  Verify.evidence(DOSSIER, page, 'champ-enregistre', "contexte=#{contexte}")
end

def choisir_les_integrations(page, demarche, cible)
  carte = page.find("#recommandation_#{demarche.recommandations.first.id}")
  carte.assert_text 'Intégrations (0)'
  dialog = Verify.fenetre(page, "Ajouter une intégration à #{cible.integree.libelle_admin}")
  liste = Verify.liste_filtrable(dialog, 'Intégrations')
  Verify.filtrer(liste, I18n.transliterate(cible.libelle).scan(/[[:alnum:]]+/).join(' ')) if liste.has_css?('[data-liste-filtrable-target=filtre]', wait: 0)
  dialog.find("label[for=demarche_integration_ids_#{cible.id}]").click
  dialog.click_button 'Enregistrer'
  verifier_les_integrations(page, demarche, cible)
end

def verifier_les_integrations(page, demarche, cible)
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector 'dialog[open]'
  page.assert_current_path("/admin/demarches/#{demarche.id}/edit", ignore_query: true)
  carte = page.find("#recommandation_#{demarche.recommandations.first.id}")
  page.scroll_to(carte, align: :center)
  texte = carte.text.squish
  raise "carte : #{texte}" unless texte.include?("Intégrations (1) #{cible.libelle.squish}")

  integrations = lu(demarche).integration_ids
  raise "intégrations en base : #{integrations}" unless integrations == [cible.id]

  Verify.evidence(DOSSIER, page, 'integrations-choisies', "carte=#{texte} base=#{integrations}")
end

def refuser(page, demarche)
  Verify.modifier_la_fiche(page, 'Nom' => '')
  page.assert_selector '.fr-input-group--error', text: 'doit être rempli'
  nom = lu(demarche).nom
  raise "nom en base : #{nom}" unless nom == demarche.nom

  Verify.evidence(DOSSIER, page, 'refuse', "message=doit être rempli nom_en_base=#{nom}")
  message = page.accept_confirm { page.find('.fr-breadcrumb').click_link 'Démarches' }
  raise "confirmation #{message.inspect}" unless message == QUESTION

  page.assert_selector 'h1', text: 'Démarches'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif fiche #{Verify.browser}"
  demarche = Demarche.create!(nom:, cree_le: Time.current, modifie_le: Time.current)
  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_2)
  cible = Integration.where(integree_id: api).order(:id).last

  Verify.check('Reach the fiche') { atteindre(page, nom) }
  Verify.check('Save a field') { enregistrer_un_champ(page, demarche) }
  Verify.check('Choose intégrations') { choisir_les_integrations(page, demarche, cible) }
  Verify.check('Refused field') { refuser(page, demarche) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom:).destroy_all
end
