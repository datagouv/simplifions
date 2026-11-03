require_relative '../harness'

DOSSIER = 'admin-recommandations-avec-la-demarche'.freeze

def apis_a_recommander = Solution.where(categorie: 'api').order(:id).reject(&:privee?).first(2)

def cartes_publiques(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  titres_des_cartes(page)
end

def ajouter(page, demarche, solution)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.onglet(page, 'Recommandations')
  page.select solution.libelle_admin, from: 'Solution de la nouvelle recommandation (obligatoire)'
  page.select 'Solution recommandée', from: 'Type de recommandation de la nouvelle recommandation (obligatoire)'
  page.click_button 'Ajouter la nouvelle recommandation'
  page.assert_selector '#message-recommandations .fr-valid-text', text: solution.libelle_admin
end

def colonne(page) = page.find('aside[aria-labelledby="etat-et-actions"]')
def titres_des_cartes(page) = page.all('.reco-card h3').map { |titre| titre.text.squish }
def en_base(demarche, api) = ActiveRecord::Base.uncached { demarche.recommandations.find_by!(solution: api) }

def publiee_avec_la_demarche(page, demarche, api)
  ajouter(page, demarche, api)
  colonne(page).click_button 'Publier'
  page.assert_text 'enregistré'
  cartes = cartes_publiques(page, demarche)
  etat = en_base(demarche, api).slice(:visible, :brouillon)
  raise "cartes #{cartes} reco #{etat}" unless cartes.size == 1 && cartes.first.include?(api.nom) && etat == { 'visible' => true, 'brouillon' => nil }

  Verify.evidence(DOSSIER, page, 'publiee-avec-la-demarche', "cartes=#{cartes} reco=#{etat}")
end

def cartes_de_l_apercu(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  colonne(page).assert_text(/brouillon non publié/i)
  fenetre = page.window_opened_by { colonne(page).click_link 'Prévisualiser' }
  page.within_window(fenetre) { titres_des_cartes(page).tap { Verify.evidence(DOSSIER, page, 'apercu', "cartes=#{it}") } }
ensure
  fenetre&.close
end

def previsualisee(page, demarche, api)
  ajouter(page, demarche, api)
  apercu = cartes_de_l_apercu(page, demarche)
  publiques = cartes_publiques(page, demarche)
  raise "aperçu #{apercu} public #{publiques}" unless apercu.size == 2 && apercu.any? { it.include?(api.nom) } && publiques.size == 1

  Verify.evidence(DOSSIER, page, 'public-inchange', "cartes=#{publiques}")
end

def lignes_apres_abandon(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.accept_confirm { colonne(page).click_button 'Abandonner le brouillon' }
  page.assert_text 'abandonné'
  Verify.onglet(page, 'Recommandations')
  page.all('tr[id^="recommandation_"]').size
end

def abandonnee(page, demarche, apis)
  lignes = lignes_apres_abandon(page, demarche)
  restantes = ActiveRecord::Base.uncached { demarche.recommandations.map(&:solution_id) }
  publiques = cartes_publiques(page, demarche)
  raise "restantes #{restantes} lignes #{lignes} public #{publiques}" unless restantes == [apis.first.id] && lignes == 1 && publiques.size == 1

  Verify.evidence(DOSSIER, page, 'abandon', "en_base=#{restantes} lignes=#{lignes} cartes=#{publiques}")
end

def publier(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  colonne(page).click_button 'Publier'
  page.assert_text 'enregistré'
end

def remontee_en_brouillon(page, demarche, api)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.onglet(page, 'Recommandations')
  page.fill_in "Ordre de la recommandation #{api.libelle_admin}", with: '0'
  page.click_button "Enregistrer la recommandation #{api.libelle_admin}"
  page.assert_selector '#message-recommandations .fr-valid-text', text: api.libelle_admin
end

def apercu_comme_publie(page, demarche, apis)
  ajouter(page, demarche, apis.last)
  publier(page, demarche)
  remontee_en_brouillon(page, demarche, apis.last)
  apercu = cartes_de_l_apercu(page, demarche)
  abandon = colonne(page).has_button?('Abandonner le brouillon', wait: 0)
  avant = cartes_publiques(page, demarche)
  apres = publier(page, demarche).then { cartes_publiques(page, demarche) }
  raise "aperçu #{apercu} avant #{avant} après #{apres} abandon #{abandon}" if abandon || [avant, apres] != [apercu.reverse, apercu]

  Verify.evidence(DOSSIER, page, 'apercu-comme-publie', "apercu=#{apercu} avant=#{avant} apres=#{apres} abandon_propose=#{abandon}")
end

Verify.drive(__FILE__) do |page|
  slug = "verif-reco-demarche-#{Verify.browser}"
  Verify.login(page)
  demarche = Demarche.create!(nom: "Vérif reco-demarche #{Verify.browser}", slug:)
  apis = apis_a_recommander

  Verify.check('Hidden démarche') { publiee_avec_la_demarche(page, demarche, apis.first) }
  Verify.check('Preview') { previsualisee(page, demarche, apis.last) }
  Verify.check('Abandon') { abandonnee(page, demarche, apis) }
  Verify.check('Preview as published') { apercu_comme_publie(page, demarche, apis) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Demarche.where(slug:).destroy_all
end
