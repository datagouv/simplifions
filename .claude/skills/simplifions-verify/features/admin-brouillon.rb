require_relative '../harness'

DOSSIER = 'admin-brouillon'.freeze
IMAGE = Rails.root.join('app/assets/images/articles/api-franceconnectees-donnees-personnelles.png').to_s
DRAFT_BADGE = /Brouillon non publié/i
RECO_EN_BROUILLON = /Brouillon — sera publiée avec la démarche/i
CHAMP_UTILE = 'En quoi cette API ou ce jeu de données est utile'.freeze

def lu(&) = ActiveRecord::Base.uncached(&)

def visiter_et_revenir(page, slug)
  page.visit("/demarches/#{slug}")
  yield.tap { page.visit('/admin') }
end

def cartes_publiques(page, slug) = visiter_et_revenir(page, slug) { page.all('.reco-card').map { it.text.squish } }

def endpoints_publics(page, slug)
  visiter_et_revenir(page, slug) { page.all('[data-endpoints-target=row]', visible: :all).map { it.text(:all).squish } }
end

def etat_de_la_ligne(page, demarche, reco)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.onglet(page, 'Recommandations')
  page.find("#recommandation_#{reco.id}").all('td')[3..].map { it.text.squish }.join(' ')
end

def publier_la_demarche(page, demarche, brouillons)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector 'aside.admin-panneau', text: brouillons
  page.click_button 'Publier'
  page.assert_text "« #{demarche.nom} » enregistré."
end

def enregistrer_le_nom(page, nom)
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
end

def brouillon_de_demarche(page, demarche)
  Verify.ouvrir_fiche(page, demarche.nom)
  enregistrer_le_nom(page, "#{demarche.nom} brouillon")
  page.assert_text "« #{demarche.nom} » : brouillon enregistré, non publié."
  page.assert_selector 'aside.admin-panneau', text: DRAFT_BADGE
  page.assert_selector 'aside.admin-panneau', text: %r{Brouillon du \d\d/\d\d/\d{4} à \d\d:\d\d}
  base = lu { demarche.reload.slice(:nom, :visible) }
  raise "brouillon : base #{base}" unless base == { 'nom' => demarche.nom, 'visible' => true }

  Verify.evidence(DOSSIER, page, 'brouillon', "base=#{base} brouillon=#{demarche.brouillon&.slice('nom')}")
end

def page_publique_inchangee(page, nom, slug)
  titre = Verify.titre_public(page, slug)
  raise "page publique #{titre}" unless titre.include?(nom) && titre.exclude?('brouillon')

  Verify.evidence(DOSSIER, page, 'page-publique-inchangee', "h1=#{titre}")
end

def rouvrir_et_publier(page, nom)
  Verify.rubrique(page, 'Démarches')
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.find_field('Nom', with: "#{nom} brouillon")
  page.click_button 'Publier'
  page.assert_text "« #{nom} brouillon » enregistré."
  page.assert_no_selector 'aside.admin-panneau', text: /Brouillon/i
end

def page_publique_publiee(page, demarche, nom)
  titre = Verify.titre_public(page, demarche.slug)
  raise "publication : page publique #{titre}" unless titre.include?("#{nom} brouillon")

  Verify.evidence(DOSSIER, page, 'page-publique-publiee', "h1=#{titre} brouillon_en_base=#{lu { demarche.reload.brouillon.inspect }}")
end

def abandonner(page, publie)
  Verify.ouvrir_fiche(page, publie)
  enregistrer_le_nom(page, "#{publie} à jeter")
  page.assert_selector 'aside.admin-panneau', text: DRAFT_BADGE
  question = "Abandonner le brouillon de « #{publie} » ? Les modifications non publiées seront perdues."
  page.accept_confirm(question) { page.click_button 'Abandonner le brouillon' }
  page.assert_text "Brouillon de « #{publie} » abandonné."
  page.find_field('Nom', with: publie)
end

def abandon_en_base(page, demarche, publie)
  base = lu { demarche.reload.slice(:nom, :brouillon) }
  raise "abandon : base #{base}" unless base == { 'nom' => publie, 'brouillon' => nil }

  Verify.evidence(DOSSIER, page, 'abandonne', "base=#{base}")
end

def envoyer_l_image(page, solution)
  Verify.rubrique(page, 'Solutions')
  Verify.ouvrir_depuis_la_liste(page, solution.nom)
  page.attach_file('solution_image', IMAGE)
  page.click_button 'Enregistrer'
end

def image_en_brouillon(page, solution)
  envoyer_l_image(page, solution)
  page.assert_selector 'aside.admin-panneau', text: DRAFT_BADGE
  page.assert_selector '.fr-upload-group img[src*="api-franceconnectees-donnees-personnelles.png"]'
  attachee = lu { Solution.find(solution.id).image.attached? }
  raise 'image en brouillon déjà attachée' if attachee

  Verify.evidence(DOSSIER, page, 'image-en-brouillon', "image_attachee=#{attachee} brouillon_image=#{solution.reload.brouillon&.key?('image')}")
end

def image_publiee(page, solution)
  page.click_button 'Publier'
  page.assert_text "« #{solution.nom} » enregistré."
  fichier = lu { Solution.find(solution.id).image.filename.to_s }
  raise "publication : image #{fichier}" unless fichier == File.basename(IMAGE)

  Verify.evidence(DOSSIER, page, 'image-publiee', "image=#{fichier} brouillon=#{solution.reload.brouillon.inspect}")
end

def modifier_une_reco_publiee(page, demarche, reco)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.onglet(page, 'Recommandations')
  page.click_link "Modifier la recommandation #{reco.solution.libelle_admin}"
  page.fill_in 'Données utiles disponibles', with: 'Après'
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: RECO_EN_BROUILLON
  Verify.evidence(DOSSIER, page, 'reco-modifiee', "base=#{lu { reco.reload.slice(:donnees_utiles, :visible) }} brouillon=#{reco.brouillon&.slice('donnees_utiles')}")
end

def ajouter_une_reco(page, demarche, ajoutee)
  page.visit("/admin/recommandations/new?demarche_id=#{demarche.id}")
  page.select ajoutee.libelle_admin, from: 'Solution (obligatoire)'
  page.select 'Solution recommandée', from: 'Type de recommandation'
  page.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} → #{ajoutee.libelle_admin} » : brouillon enregistré, non publié."
  page.assert_selector 'aside.admin-panneau', text: /Masquée.*Brouillon — sera publiée avec la démarche/im
end

def reco_ajoutee_en_base(page, demarche, ajoutee)
  nouvelle = lu { demarche.recommandations.find_by!(solution: ajoutee) }
  Verify.evidence(DOSSIER, page, 'reco-ajoutee', "visible=#{nouvelle.visible} brouillon=#{nouvelle.brouillon.slice('visible')}")
end

def cartes_avant_publication(page, demarche)
  cartes = cartes_publiques(page, demarche.slug)
  raise "page publique avant : #{cartes}" unless cartes.size == 1 && cartes.first.include?('Avant')

  Verify.evidence(DOSSIER, page, 'page-publique-avant', "cartes=#{cartes.size}")
end

def cartes_apres_publication(page, demarche)
  publier_la_demarche(page, demarche, '2 recommandations en brouillon')
  page.assert_no_selector 'aside.admin-panneau', text: 'en brouillon'
  cartes = cartes_publiques(page, demarche.slug)
  raise "page publique après : #{cartes}" unless cartes.size == 2 && cartes.join.include?('Après')

  Verify.evidence(DOSSIER, page, 'page-publique-apres', "cartes=#{cartes.size} brouillons=#{lu { demarche.recommandations_en_brouillon.count }}")
end

def brouillon_recommandations(page, demarche, nom)
  modifiee, ajoutee = %w[a b].map { Solution.create!(nom: "#{nom} #{it}", categorie: 'api') }
  reco = Recommandation.create!(demarche:, solution: modifiee, niveau: :niveau_2, donnees_utiles: 'Avant', visible: true)
  modifier_une_reco_publiee(page, demarche, reco)
  ajouter_une_reco(page, demarche, ajoutee)
  reco_ajoutee_en_base(page, demarche, ajoutee)
  cartes_avant_publication(page, demarche)
  cartes_apres_publication(page, demarche)
end

def donnee_utile_publiee(demarche, nom)
  bouquet = Solution.create!(nom: "#{nom} bouquet", categorie: 'brique_logicielle', organisations: [Organisation.find_by!(public_ou_prive: 'Public')])
  api = Solution.create!(nom: "#{nom} c", categorie: 'api')
  Integration.create!(integratrice: bouquet, integree: api, type_integration: 'expose')
  Recommandation.create!(demarche:, solution: bouquet, niveau: :niveau_2, visible: true)
  Recommandation.create!(demarche:, solution: api, niveau: :niveau_1, description: 'Utile avant', visible: true)
end

def ligne_publiee(page, demarche, utile, etape)
  etat = etat_de_la_ligne(page, demarche, utile)
  raise "#{etape} : état #{etat}" unless etat.match?(/\Apubliée/i) && !etat.match?(/brouillon/i)

  Verify.evidence(DOSSIER, page, etape, "état=#{etat}")
end

def sans_publier_ni_masquer(page, utile)
  page.click_link "Modifier la recommandation #{utile.solution.libelle_admin}"
  page.find_field CHAMP_UTILE
  actions = page.find('aside.admin-panneau').all('button').map(&:text)
  raise "donnée utile : actions #{actions}" if actions.intersect?(%w[Publier Masquer])

  Verify.evidence(DOSSIER, page, 'donnee-utile-actions', "actions=#{actions}")
end

def donnee_utile_en_brouillon(page, demarche, utile)
  page.fill_in CHAMP_UTILE, with: 'Utile après'
  page.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} → #{utile.solution.libelle_admin} » : brouillon enregistré, non publié."
  base = lu { utile.reload.slice(:description, :visible) }
  raise "donnée utile modifiée : base #{base}" unless base == { 'description' => 'Utile avant', 'visible' => true }

  Verify.evidence(DOSSIER, page, 'donnee-utile-modifiee', "base=#{base} brouillon=#{utile.brouillon&.slice('description')}")
end

def endpoints_attendus(page, demarche, present, absent, etape)
  lignes = endpoints_publics(page, demarche.slug).join(' / ')
  raise "#{etape} : #{lignes}" unless lignes.include?(present) && (absent.nil? || lignes.exclude?(absent))

  Verify.evidence(DOSSIER, page, etape, "lignes=#{lignes}")
end

def brouillon_donnees_utiles(page, demarche, nom)
  utile = donnee_utile_publiee(demarche, nom)
  ligne_publiee(page, demarche, utile, 'donnee-utile-publiee')
  sans_publier_ni_masquer(page, utile)
  donnee_utile_en_brouillon(page, demarche, utile)
  endpoints_attendus(page, demarche, 'Utile avant', 'Utile après', 'donnee-utile-public-avant')
  publier_la_demarche(page, demarche, '1 recommandation en brouillon')
  endpoints_attendus(page, demarche, 'Utile après', nil, 'donnee-utile-public-apres')
  ligne_publiee(page, demarche, utile, 'donnee-utile-ligne-apres')
end

def actions_selon_le_type(page, type)
  page.select type, from: 'Type de recommandation'
  page.within('aside.admin-panneau') do
    type == 'Solution recommandée' ? page.assert_selector(:button, 'Publier') : page.assert_no_selector(:button, 'Publier')
    page.all('button').map(&:text)
  end
end

def actions_par_type(page, ecran)
  utile = actions_selon_le_type(page, 'Donnée utile (API ou jeu de données)')
  raise "#{ecran}, type donnée utile : actions #{utile}" if utile.intersect?(%w[Publier Masquer])

  Verify.evidence(DOSSIER, page, "type-choisi-#{ecran}-donnee-utile", "actions=#{utile}")
  recommandee = actions_selon_le_type(page, 'Solution recommandée')
  Verify.evidence(DOSSIER, page, "type-choisi-#{ecran}-solution-recommandee", "actions=#{recommandee}")
end

def brouillon_type_choisi(page, demarche, nom)
  masquee = Recommandation.create!(demarche:, solution: Solution.create!(nom: "#{nom} d", categorie: 'api'), niveau: :niveau_2)
  { 'nouvelle' => "/admin/recommandations/new?demarche_id=#{demarche.id}", 'masquee' => "/admin/recommandations/#{masquee.id}/edit" }.each do |ecran, chemin|
    page.visit(chemin)
    actions_par_type(page, ecran)
  end
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  publie = "#{nom} brouillon"
  Verify.login(page)
  demarche = Demarche.create!(nom:, slug:, visible: true)

  Verify.check('Draft') { brouillon_de_demarche(page, demarche) }
  Verify.check('Public page unchanged') { page_publique_inchangee(page, nom, slug) }
  Verify.check('Reopen and publish') { rouvrir_et_publier(page, nom).then { page_publique_publiee(page, demarche, nom) } }
  Verify.check('Abandon') { abandonner(page, publie).then { abandon_en_base(page, demarche, publie) } }
  Verify.check('Image') do
    solution = Solution.create!(nom:, slug:, visible: true)
    image_en_brouillon(page, solution).then { image_publiee(page, solution) }
  end
  Verify.check('Recommandations') { brouillon_recommandations(page, demarche.reload, nom) }
  Verify.check('Données utiles') { brouillon_donnees_utiles(page, demarche, nom) }
  Verify.check('Type chosen') { brouillon_type_choisi(page, demarche, nom) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).or(Solution.where(nom: ["#{nom} a", "#{nom} b", "#{nom} bouquet", "#{nom} c", "#{nom} d"])).destroy_all
end
