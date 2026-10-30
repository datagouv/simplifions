require_relative '../harness'

DOSSIER = 'admin-fournisseurs-de-services'.freeze
RUBRIQUE = 'Fournisseurs de services'.freeze

def definition(page, terme) = page.find('dt', text: terme, exact_text: true).find(:xpath, 'following-sibling::dd[1]').text

def cases_cochees(page) = page.find('fieldset', text: 'Regroupements', match: :first).all('input[type=checkbox]', visible: :all).select(&:checked?).map(&:value)

def lire_une_vraie_ligne(page, reel)
  Verify.rubrique(page, RUBRIQUE)
  page.assert_selector 'h1', text: RUBRIQUE
  Verify.ouvrir_depuis_la_liste(page, reel.nom)
  page.assert_current_path("/admin/types_acteurs/#{reel.id}")
  lu = definition(page, 'Regroupements')
  raise "fiche #{lu}" unless lu == reel.regroupements.join(', ')

  Verify.evidence(DOSSIER, page, 'consultation', "url=#{page.current_path} regroupements=#{lu} base=#{reel.slugs.join(',')}")
end

def formulaire(page, reel)
  page.click_link 'Modifier'
  page.assert_current_path("/admin/types_acteurs/#{reel.id}/edit")
  raise "cochées #{cases_cochees(page)} != #{reel.slugs}" unless cases_cochees(page).sort == (reel.slugs & TypeActeur::FILTRES.values).sort

  Verify.evidence(DOSSIER, page, 'formulaire', "cochees=#{cases_cochees(page).join(',')} memos=#{memo(page)}")
end

def memo(page)
  memos = %w[description codes_juridiques].map { |champ| page.find("label[for=type_acteur_#{champ}] .fr-hint-text").text }
  raise "mémos #{memos}" unless memos.uniq == ['Mémo interne, non affiché sur le site']

  memos.first
end

def creer(page, nom)
  page.visit('/admin/types_acteurs/new')
  page.fill_in 'Nom', with: nom
  page.check 'Régions', allow_label_click: true
  page.check 'Tous les acteurs publics', allow_label_click: true
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  ligne = TypeActeur.find_by!(nom:)
  page.assert_current_path("/admin/types_acteurs/#{ligne.id}")
  Verify.evidence(DOSSIER, page, 'cree', "url=#{page.current_path} slugs=#{ligne.slugs.join(',')} affiche=#{definition(page, 'Regroupements')} onglet=#{page.title}")
  ligne
end

def decocher(page, ligne)
  page.click_link 'Modifier'
  page.uncheck 'Régions', allow_label_click: true
  page.click_button 'Enregistrer'
  page.assert_text "« #{ligne.nom} » enregistré."
  slugs = ActiveRecord::Base.uncached { TypeActeur.find(ligne.id).slugs }
  raise "slugs #{slugs}" unless slugs == %w[tout-acteurs-publics]

  Verify.evidence(DOSSIER, page, 'decoche', "url=#{page.current_path} slugs=#{slugs.join(',')} affiche=#{definition(page, 'Regroupements')}")
end

def colonne_de_la_liste(page, nom)
  Verify.rubrique(page, RUBRIQUE)
  Verify.rechercher(page, nom)
  colonne = page.find('tbody tr', text: nom).all('td').last.text
  raise "colonne #{colonne}" unless colonne == 'Tous les acteurs publics'

  Verify.evidence(DOSSIER, page, 'liste', "regroupements=#{colonne}")
end

def supprimer(page, ligne)
  page.visit("/admin/types_acteurs/#{ligne.id}/edit")
  page.accept_confirm("Supprimer « #{ligne.nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{ligne.nom} » supprimé."
  reste = ActiveRecord::Base.uncached { TypeActeur.where(nom: ligne.nom).count }
  raise "reste_en_base=#{reste}" unless reste.zero?

  Verify.evidence(DOSSIER, page, 'supprime', "reste_en_base=#{reste}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  reel = TypeActeur.where.not(slugs: []).order(:id).first
  Verify.login(page)
  Verify.check('Read a real row') { lire_une_vraie_ligne(page, reel) }
  Verify.check('Edit form') { formulaire(page, reel) }
  ligne = Verify.check('Create') { creer(page, nom) }
  Verify.check('Untick') do
    decocher(page, ligne)
    colonne_de_la_liste(page, nom)
  end
  Verify.check('Delete') do
    supprimer(page, ligne)
    Verify.logout(page)
  end
ensure
  TypeActeur.where(nom:).destroy_all
end
