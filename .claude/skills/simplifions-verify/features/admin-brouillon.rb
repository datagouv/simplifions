require_relative '../harness'

DOSSIER = 'admin-brouillon'.freeze
IMAGE = Rails.root.join('app/assets/images/articles/api-franceconnectees-donnees-personnelles.png').to_s
DRAFT_BADGE = /Brouillon non publié/i
RECO_EN_BROUILLON = /Brouillon — sera publiée avec la démarche/i
SANS_BROUILLON = 'Pas de brouillon : « Enregistrer » met en ligne tout de suite.'.freeze
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
  badge = page.find("form#donnee_utile_recommandation_#{reco.id}", visible: :all).all('.fr-badge', visible: :all).map { it.text(:all).squish }
  [*badge, ('brouillon' if lu { reco.reload.brouillon? })].compact.join(' ')
end

def publier_la_demarche(page, demarche, brouillons)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector Verify::BARRE_DEMARCHE, text: brouillons
  page.click_button 'Publier'
  page.assert_text "« #{demarche.nom} » enregistré."
end

def enregistrer_le_nom(page, nom) = Verify.modifier_dans_la_fenetre(page, 'Modifier l’en-tête', 'Nom' => nom)

def brouillon_de_demarche(page, demarche)
  Verify.ouvrir_fiche(page, demarche.nom)
  enregistrer_le_nom(page, "#{demarche.nom} brouillon")
  page.assert_text "« #{demarche.nom} » : brouillon enregistré, non publié."
  page.assert_selector Verify::BARRE_DEMARCHE, text: DRAFT_BADGE
  page.assert_selector Verify::BARRE_DEMARCHE, text: %r{Brouillon du \d\d/\d\d/\d{4} à \d\d:\d\d}
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
  page.assert_selector 'h1', exact_text: "#{nom} brouillon"
  page.click_button 'Publier'
  page.assert_text "« #{nom} brouillon » enregistré."
  page.assert_no_selector Verify::BARRE_DEMARCHE, text: /Brouillon/i
end

def page_publique_publiee(page, demarche, nom)
  titre = Verify.titre_public(page, demarche.slug)
  raise "publication : page publique #{titre}" unless titre.include?("#{nom} brouillon")

  Verify.evidence(DOSSIER, page, 'page-publique-publiee', "h1=#{titre} brouillon_en_base=#{lu { demarche.reload.brouillon.inspect }}")
end

def abandonner(page, publie)
  Verify.ouvrir_fiche(page, publie)
  enregistrer_le_nom(page, "#{publie} à jeter")
  page.assert_selector Verify::BARRE_DEMARCHE, text: DRAFT_BADGE
  question = "Abandonner le brouillon de « #{publie} » ? Les modifications non publiées seront perdues."
  page.accept_confirm(question) { page.click_button 'Abandonner le brouillon' }
  page.assert_text "Brouillon de « #{publie} » abandonné."
  page.assert_selector 'h1', exact_text: publie
end

def abandon_en_base(page, demarche, publie)
  base = lu { demarche.reload.slice(:nom, :brouillon) }
  raise "abandon : base #{base}" unless base == { 'nom' => publie, 'brouillon' => nil }

  Verify.evidence(DOSSIER, page, 'abandonne', "base=#{base}")
end

ENCADRE = 'section[aria-labelledby="a-la-publication"]'.freeze

def lignes_de_l_encadre(page, titre)
  page.assert_selector '#a-la-publication', exact_text: titre
  page.find(ENCADRE).all('li a.fr-link').map { it.text.squish }
end

def ce_qui_partira(page, demarche, nom)
  ajoutee = Solution.create!(nom: "#{nom} g", categorie: 'api')
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_no_selector ENCADRE
  Verify.modifier_dans_la_fenetre(page, 'Modifier le contexte', 'Contexte' => 'Vérif ce qui partira')
  lignes = lignes_de_l_encadre(page, 'À la publication, 1 changement partira')
  raise "encadré après le contexte : #{lignes}" unless lignes == ['Contexte modifié']

  Verify.ajouter_une_solution_recommandee(page, ajoutee)
  lignes = lignes_de_l_encadre(page, 'À la publication, 2 changements partiront')
  raise "encadré après l’ajout sur place : #{lignes}" unless lignes == ['Contexte modifié', "Solution recommandée ajoutée : #{ajoutee.libelle_admin}"]

  page.find(ENCADRE).click_link 'Contexte modifié'
  ancre = page.document.synchronize do
    page.evaluate_script('location.hash').tap { raise Capybara::ExpectationNotMet, "lien du contexte : #{it}" unless it == '#bloc-contexte' }
  end

  Verify.evidence(DOSSIER, page, 'ce-qui-partira', "lignes=#{lignes} ancre=#{ancre}")
  page.find(ENCADRE).click_button 'Publier ces 2 changements'
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector ENCADRE
  base = lu { [demarche.reload.slice(:contexte, :brouillon), demarche.recommandations.find_by!(solution: ajoutee).visible] }
  raise "publication de l’encadré : base #{base}" unless base == [{ 'contexte' => 'Vérif ce qui partira', 'brouillon' => nil }, true]

  Verify.evidence(DOSSIER, page, 'ce-qui-partira-publie', "base=#{base}")
  ajoutee.destroy!
end

def carte_retiree(page, reco)
  carte = page.find("#recommandation_#{reco.id}")
  [carte[:class].include?('retiree'), carte.all('s').map(&:text), carte.all('.fr-badge').map { it.text.squish.downcase }, carte.all('button').map { it.text.squish }]
end

def retirer_la_carte(page, demarche, reco)
  nom = reco.solution.libelle_admin
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.accept_confirm("Supprimer la recommandation #{nom} ?") { page.click_button "Retirer #{nom}" }
  page.assert_selector '#message-recommandations .fr-valid-text', text: 'brouillon enregistré, non publié'
  page.assert_selector "#recommandation_#{reco.id}.retiree"
end

def retrait_barre(page, demarche, reco)
  nom = reco.solution.libelle_admin
  retirer_la_carte(page, demarche, reco)
  vu = carte_retiree(page, reco)
  raise "carte retirée : #{vu}" unless vu == [true, [nom], ['retirée · à publier'], ["Remettre #{nom}"]]

  lignes = lignes_de_l_encadre(page, 'À la publication, 1 changement partira')
  raise "encadré du retrait : #{lignes}" unless lignes == ["Solution recommandée retirée : #{nom}"]

  Verify.evidence(DOSSIER, page, 'retrait-barre', "carte=#{vu} lignes=#{lignes} brouillon=#{lu { reco.reload.brouillon&.slice('retiree') }}")
  publique = cartes_publiques(page, demarche.slug).join
  raise 'retrait déjà en ligne' unless publique.include?(reco.solution.nom) && lu { Recommandation.exists?(reco.id) }

  page.visit("/admin/demarches/#{demarche.id}/edit")
end

def retrait_remis(page, reco)
  page.click_button "Remettre #{reco.solution.libelle_admin}"
  page.assert_no_selector "#recommandation_#{reco.id}.retiree"
  page.assert_no_selector ENCADRE
  vu = carte_retiree(page, reco)
  brouillon = lu { reco.reload.brouillon }
  raise "remise : carte #{vu} brouillon #{brouillon}" unless vu.first == false && vu.last.first == "Modifier #{reco.solution.libelle_admin}" && brouillon.nil?

  Verify.evidence(DOSSIER, page, 'retrait-remis', "carte=#{vu} brouillon=#{brouillon.inspect}")
end

def retrait_publie(page, demarche, reco)
  retirer_la_carte(page, demarche, reco)
  page.find(ENCADRE).click_button 'Publier ce changement'
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector "#recommandation_#{reco.id}"
  publique = cartes_publiques(page, demarche.slug).join
  raise 'retrait publié : encore sur le site ou en base' if publique.include?(reco.solution.nom) || lu { Recommandation.exists?(reco.id) }

  Verify.evidence(DOSSIER, page, 'retrait-publie', "en_base=false cartes_publiques=#{publique.first(80)}")
end

def retrait_en_brouillon(page, demarche, nom)
  reco = Recommandation.create!(demarche:, solution: Solution.create!(nom: "#{nom} h", categorie: 'api'), niveau: :niveau_2, visible: true)
  retrait_barre(page, demarche, reco)
  retrait_remis(page, reco)
  retrait_publie(page, demarche, reco)
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

def modifier_une_reco_publiee(page, reco)
  page.visit("/admin/recommandations/#{reco.id}/edit")
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
  page.assert_no_selector Verify::BARRE_DEMARCHE, text: 'en brouillon'
  cartes = cartes_publiques(page, demarche.slug)
  raise "page publique après : #{cartes}" unless cartes.size == 2 && cartes.join.include?('Après')

  Verify.evidence(DOSSIER, page, 'page-publique-apres', "cartes=#{cartes.size} brouillons=#{lu { demarche.recommandations_en_brouillon.count }}")
end

def brouillon_recommandations(page, demarche, nom)
  modifiee, ajoutee = %w[a b].map { Solution.create!(nom: "#{nom} #{it}", categorie: 'api') }
  reco = Recommandation.create!(demarche:, solution: modifiee, niveau: :niveau_2, donnees_utiles: 'Avant', visible: true)
  modifier_une_reco_publiee(page, reco)
  ajouter_une_reco(page, demarche, ajoutee)
  reco_ajoutee_en_base(page, demarche, ajoutee)
  cartes_avant_publication(page, demarche)
  cartes_apres_publication(page, demarche)
end

def reco_publiee_modifiee(page, demarche, nom)
  solution = Solution.create!(nom: "#{nom} i", categorie: 'api')
  reco = Recommandation.create!(demarche:, solution:, niveau: :niveau_2, description: 'Description d’origine', visible: true)
  page.visit("/admin/recommandations/#{reco.id}/edit")
  page.fill_in CHAMP_UTILE, with: 'Description à jeter'
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: RECO_EN_BROUILLON
  page.visit("/admin/demarches/#{demarche.id}/edit")
  lignes = lignes_de_l_encadre(page, 'À la publication, 1 changement partira')
  raise "encadré de la reco modifiée : #{lignes}" unless lignes == ["Solution recommandée modifiée : #{solution.libelle_admin}"]

  Verify.evidence(DOSSIER, page, 'reco-publiee-modifiee', "lignes=#{lignes}")
  reco
end

def abandon_d_une_reco_publiee(page, demarche, nom)
  reco = reco_publiee_modifiee(page, demarche, nom)
  question = "Abandonner le brouillon de « #{demarche.nom} » ? Les modifications non publiées seront perdues."
  page.accept_confirm(question) { page.find(ENCADRE).click_button 'Abandonner le brouillon' }
  page.assert_text "Brouillon de « #{demarche.nom} » abandonné."
  page.assert_no_selector ENCADRE
  page.visit("/admin/recommandations/#{reco.id}/edit")
  champ = page.find_field(CHAMP_UTILE).value
  base = lu { reco.reload.slice(:description, :brouillon) }
  raise "abandon de la reco : champ #{champ}, base #{base}" unless champ == 'Description d’origine' && base == { 'description' => 'Description d’origine', 'brouillon' => nil }

  Verify.evidence(DOSSIER, page, 'reco-publiee-abandonnee', "champ=#{champ} base=#{base}")
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
  raise "#{etape} : état #{etat}" unless etat.empty?

  Verify.evidence(DOSSIER, page, etape, "état=#{etat}")
end

def sans_publier_ni_masquer(page, utile)
  page.visit("/admin/recommandations/#{utile.id}/edit")
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

PANNEAU = "aside[aria-labelledby='etat-et-actions'], #{Verify::BARRE_DEMARCHE}".freeze

def phrase_du_panneau(page) = page.find(PANNEAU).all('p').map { it.text.squish }.include?(SANS_BROUILLON)

def panneau_sans_brouillon(page, etape, chemin, attendu)
  page.visit(chemin)
  page.assert_selector PANNEAU
  dit = phrase_du_panneau(page)
  raise "#{etape} : phrase #{dit ? 'présente' : 'absente'} du panneau" unless dit == attendu

  Verify.evidence(DOSSIER, page, "sans-brouillon-#{etape}", "phrase=#{dit}")
end

ONGLETS_D_INTEGRATIONS = { 'api-fournies' => 'API fournies', 'api-integrees' => 'API intégrées', 'integratrices' => 'Solutions qui l’intègrent' }.freeze

def phrase_des_onglets_d_integrations(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  ONGLETS_D_INTEGRATIONS.each do |onglet, libelle|
    Verify.onglet(page, libelle)
    texte = page.find("#onglet-#{onglet}-panneau").text.squish
    raise "onglet #{libelle} : #{texte.first(120)}" unless texte.start_with?("#{SANS_BROUILLON} #{libelle}")

    Verify.evidence(DOSSIER, page, "sans-brouillon-onglet-#{onglet}", "début=#{texte.first(100)}")
  end
end

def brouillon_fiches_sans_brouillon(page, demarche, nom)
  bouquet = Solution.create!(nom: "#{nom} e")
  api = Solution.create!(nom: "#{nom} f", categorie: 'api')
  integration = Integration.create!(integratrice: bouquet, integree: api, type_integration: 'consomme')
  reco = Recommandation.create!(demarche:, solution: api, niveau: :niveau_1, visible: true)
  sans = {
    'integration' => "/admin/integrations/#{integration.id}/edit",
    'organisation' => "/admin/organisations/#{Organisation.create!(nom: "#{nom} org").id}/edit",
    'fournisseur' => "/admin/types_acteurs/#{TypeActeur.create!(nom: "#{nom} fournisseur").id}/edit",
    'vocabulaire' => "/admin/vocabulaires/#{Vocabulaire.create!(nom: "#{nom} voc", slug: "#{nom.parameterize}-voc", categorie: 'usager').id}/edit"
  }
  sans.each { |etape, chemin| panneau_sans_brouillon(page, etape, chemin, true) }
  phrase_des_onglets_d_integrations(page, bouquet)
  panneau_sans_brouillon(page, 'demarche-absente', "/admin/demarches/#{demarche.id}/edit", false)
  panneau_sans_brouillon(page, 'solution-absente', "/admin/solutions/#{bouquet.id}/edit", false)
  panneau_sans_brouillon(page, 'recommandation-absente', "/admin/recommandations/#{reco.id}/edit", false)
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
  Verify.check('What will go out') { ce_qui_partira(page, demarche, nom) }
  Verify.check('Removal waits') { retrait_en_brouillon(page, demarche.reload, nom) }
  Verify.check('Image') do
    solution = Solution.create!(nom:, slug:, visible: true)
    image_en_brouillon(page, solution).then { image_publiee(page, solution) }
  end
  Verify.check('Recommandations') { brouillon_recommandations(page, demarche.reload, nom) }
  Verify.check('Abandon of a published recommandation') { abandon_d_une_reco_publiee(page, demarche.reload, nom) }
  Verify.check('Données utiles') { brouillon_donnees_utiles(page, demarche, nom) }
  Verify.check('Type chosen') { brouillon_type_choisi(page, demarche, nom) }
  Verify.check('No draft') { brouillon_fiches_sans_brouillon(page, demarche, nom) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).or(Solution.where(nom: ["#{nom} a", "#{nom} b", "#{nom} bouquet", "#{nom} c", "#{nom} d", "#{nom} e", "#{nom} f", "#{nom} g", "#{nom} h", "#{nom} i"])).destroy_all
  Organisation.where(nom: "#{nom} org").destroy_all
  TypeActeur.where(nom: "#{nom} fournisseur").destroy_all
  Vocabulaire.where(nom: "#{nom} voc").destroy_all
end
