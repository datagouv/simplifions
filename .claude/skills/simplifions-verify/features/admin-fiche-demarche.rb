require_relative '../harness'

DOSSIER = 'admin-fiche-demarche'.freeze

def atteindre(page, nom)
  Verify.login(page)
  Verify.rubrique(page, 'Démarches')
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.assert_selector 'h1', text: nom
  page.assert_no_selector 'aside'
  page.assert_selector :button, 'Modifier le contexte'
end

def enregistrer_un_bloc(page, demarche)
  Verify.fenetre(page, 'Modifier le contexte').fill_in 'Contexte', with: 'Contexte modifié par la vérif'
  page.find('dialog[open]').click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector 'dialog[open]'
  page.find('section', text: 'Contexte').assert_text 'Contexte modifié par la vérif'
  lu = ActiveRecord::Base.uncached { Demarche.find(demarche.id).contexte }
  raise "contexte en base : #{lu}" unless lu == 'Contexte modifié par la vérif'

  Verify.evidence(DOSSIER, page, 'bloc-enregistre', "contexte=#{lu}")
end

def annuler_par_echap(page, demarche)
  Verify.fenetre(page, 'Modifier l’en-tête').fill_in 'Nom', with: 'Nom abandonné'
  page.find('dialog[open]').send_keys(:escape)
  page.assert_no_selector 'dialog[open]'
  page.assert_selector '#formulaire-fiche[data-formulaire-modifie-modifie-value=false]'
  lu = ActiveRecord::Base.uncached { Demarche.find(demarche.id).nom }
  raise "nom en base : #{lu}" unless lu == demarche.nom

  valeur = Verify.fenetre(page, 'Modifier l’en-tête').find_field('Nom').value
  raise "nom rouvert : #{valeur}" unless valeur == demarche.nom

  page.find('dialog[open]').click_button 'Annuler'
  page.assert_no_selector 'dialog[open]'
  "nom_en_base=#{lu} nom_rouvert=#{valeur}"
end

def choisir_les_integrations(page, demarche, cible)
  bloc = page.find('section', text: /\AIntégrations/)
  bloc.assert_text '0 cochée sur'
  dialog = Verify.fenetre(page, 'Choisir les intégrations')
  dialog.fill_in 'Filtrer les intégrations', with: I18n.transliterate(cible.libelle).scan(/[[:alnum:]]+/).join(' ')
  dialog.find("label[for=demarche_integration_ids_#{cible.id}]").click
  dialog.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector 'dialog[open]'
  page.assert_current_path("/admin/demarches/#{demarche.id}/edit", ignore_query: true)
  bloc = page.find('section', text: /\AIntégrations/)
  page.scroll_to(bloc, align: :center)
  texte = bloc.find('p').text
  raise "bloc : #{texte}" unless texte.start_with?('1 cochée sur ')

  lu = ActiveRecord::Base.uncached { Demarche.find(demarche.id).integration_ids }
  raise "intégrations en base : #{lu}" unless lu == [cible.id]

  Verify.evidence(DOSSIER, page, 'integrations-choisies', "bloc=#{texte} base=#{lu}")
end

def refuser(page, demarche)
  Verify.fenetre(page, 'Modifier l’en-tête').fill_in 'Nom', with: ''
  page.find('dialog[open]').click_button 'Enregistrer'
  page.assert_selector 'dialog[open] .fr-input-group--error', text: 'doit être rempli'
  Verify.evidence(DOSSIER, page, 'refuse', 'fenetre=ouverte message=doit être rempli')
  page.find('dialog[open]').click_button 'Annuler'
  page.assert_no_selector 'dialog[open]'
  page.assert_selector "#demarche_nom[value='#{demarche.nom}']", visible: :all

  page.find('.fr-breadcrumb').click_link 'Démarches'
  page.assert_selector 'h1', text: 'Démarches'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif fiche #{Verify.browser}"
  demarche = Demarche.create!(nom:, cree_le: Time.current, modifie_le: Time.current)
  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_1)
  cible = Integration.where(integree_id: api).order(:id).last

  Verify.check('Reach the fiche') { atteindre(page, nom) }
  Verify.check('Save a block') { enregistrer_un_bloc(page, demarche) }
  Verify.check('Cancel with Escape') { annuler_par_echap(page, demarche) }
  Verify.check('Choose intégrations') { choisir_les_integrations(page, demarche, cible) }
  Verify.check('Refused field') { refuser(page, demarche) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom:).destroy_all
end
