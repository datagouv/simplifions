require_relative '../harness'

DOSSIER = 'admin-recommandations-en-ligne'.freeze

def carte_a_completer(demarche)
  fiche = demarche.recommandations.sur_la_fiche
  cartes = fiche.select(&:niveau_2?)
  donnees = Demarche.rattachement(cartes, fiche.select(&:niveau_1?), &:solution_id)
  cochees = Demarche.find(demarche.id).appliquer_brouillon.integration_ids
  integrations = Demarche.rattachement(cartes, demarche.integrations_proposees.to_a, &:integree_id)
  cartes.find do |carte|
    !carte.retiree? && donnees[carte].present? && (carte.solution.exposee_ids - fiche.map(&:solution_id)).any? &&
      integrations.fetch(carte, []).any? { !it.id.in?(cochees) }
  end
end

def contexte
  demarches = Demarche.visibles.where.not(slug: [nil, '']).sort_by { -it.recommandations.niveau_2.count }
  demarche, carte = demarches.lazy.filter_map { |ligne| [ligne, carte_a_completer(ligne)] if carte_a_completer(ligne) }.first
  solution = Solution.where(categorie: 'api').where.not(id: demarche.recommandations.select(:solution_id)).reject(&:privee?).first
  { demarche:, solution:, a_completer: carte, brouillon: demarche.brouillon,
    avant: demarche.recommandations.to_h { [it.id, it.attributes.slice('ordre', 'brouillon')] } }
end

def lu(&) = ActiveRecord::Base.uncached(&)
def fiche(ctx) = lu { ctx[:demarche].recommandations.sur_la_fiche }
def cartes_publiques(page, demarche) = page.visit("/demarches/#{demarche.slug}").then { page.all('.reco-card').map(&:text) }
def titre(page, id) = page.find("##{id}").text.squish

def cartes(page, ctx)
  page.visit("/admin/demarches/#{ctx[:demarche].id}/edit")
  attendu = fiche(ctx).partition(&:niveau_2?).map(&:size)
  lu_ = [titre(page, 'bloc-solutions-recommandees'), page.all('.donnees-disponibles li').size]
  raise "titre et données utiles #{lu_} pour #{attendu}" unless lu_ == ["Solutions recommandées (#{attendu.first})", attendu.last]

  ctx[:carte] = fiche(ctx).find(&:niveau_2?)
  Verify.evidence(DOSSIER, page, 'cartes', "titres=#{lu_} premiere=#{Verify.cartes_de_la_fiche(page).first.find('p').text}")
end

def modifier(page, ctx)
  carte = ctx[:carte]
  Verify.modifier_la_carte(page, carte.solution, 'Position' => '77')
  page.find("#recommandation_#{carte.id}").assert_text 'Position 77'
  focus = Verify.focus_sur(page)
  base = lu { carte.reload.slice(:ordre, :brouillon) }
  raise "focus #{focus}" unless focus == "modifier_recommandation_#{carte.id}"
  raise "base #{base}" unless base['ordre'] == ctx[:avant][carte.id]['ordre'] && base['brouillon']&.dig('ordre').to_s == '77'

  Verify.evidence(DOSSIER, page, 'modifiee', "message=#{page.find('#message-recommandations').text} focus=#{focus} ordre_en_base=#{base['ordre']} brouillon=#{base['brouillon']['ordre']}")
end

def erreur(page)
  Verify.fenetre(page, 'Ajouter une solution recommandée').click_button 'Enregistrer'
  erreur = page.find('dialog[open] .fr-message--error', text: 'Choisissez une solution')
  Verify.evidence(DOSSIER, page, 'erreur', "fenetre=#{page.find('dialog[open] h2').text} erreur=#{erreur.text}")
end

def ajouter(page, ctx)
  dialog = page.find('dialog[open]')
  dialog.select ctx[:solution].libelle_admin, from: 'Solution (obligatoire)'
  dialog.click_button 'Enregistrer'
  page.assert_selector '#message-recommandations .fr-valid-text', text: ctx[:solution].libelle_admin
  ctx[:ajoutee] = lu { ctx[:demarche].recommandations.find_by!(solution: ctx[:solution]) }
  page.find("#recommandation_#{ctx[:ajoutee].id}").assert_text(/Ajoutée au brouillon/i)
  compte = titre(page, 'bloc-solutions-recommandees')
  Verify.evidence(DOSSIER, page, 'ajoutee', "titre=#{compte} visible=#{ctx[:ajoutee].visible} brouillon=#{ctx[:ajoutee].brouillon.slice('visible')}")
end

def changer_l_ordre(page, ctx)
  methode = Verify.glisser(page, '#message-recommandations .fr-valid-text', 'déplacée en position 1') do
    page.visit("/admin/demarches/#{ctx[:demarche].id}/edit")
    page.assert_no_text 'Glissez une carte par sa poignée'
    page.click_button 'Changer l’ordre'
    page.assert_text 'Glissez une carte par sa poignée'
    page.assert_selector '#changer-l-ordre[aria-expanded=true]'
    poignees = page.all('.cartes-recommandees [data-poignee]', minimum: 2)
    ctx[:glissee] = poignees[1].find(:xpath, 'ancestor::li[1]')[:id]
    page.execute_script('arguments[0].scrollIntoView({ block: "center" })', poignees.first)
    [poignees[1], poignees.first]
  end
  raise 'mode « Changer l’ordre » refermé après le glisser' unless page.has_selector?('#changer-l-ordre[aria-expanded=true]') && page.has_selector?('.cartes-recommandees [data-poignee]')

  premiere = Verify.cartes_de_la_fiche(page).first[:id]
  en_base = "recommandation_#{fiche(ctx).find(&:niveau_2?).id}"
  raise "première carte #{premiere}, en base #{en_base}, glissée #{ctx[:glissee]}" unless [premiere, en_base].uniq == [ctx[:glissee]]

  Verify.evidence(DOSSIER, page, 'ordre-change', "methode=#{methode} message=#{page.find('#message-recommandations').text}")
end

def donnees_utiles(page, ctx)
  carte = ctx[:a_completer]
  fenetre = "donnees-utiles-recommandation_#{carte.id}"
  page.visit("/admin/demarches/#{ctx[:demarche].id}/edit")
  dialog = Verify.fenetre(page, "Ajouter une donnée utile à #{carte.solution.libelle_admin.squish}")
  raise "fenêtre ouverte #{dialog[:id]}" unless dialog[:id] == "fenetre-#{fenetre}"

  ligne = dialog.first('fieldset')
  nom = ligne.find('legend').text.delete_prefix('Donnée utile : ')
  ligne.fill_in 'Position', with: '55'
  ligne.click_button 'Enregistrer'
  page.assert_selector "#message-#{fenetre} .fr-valid-text", text: nom
  raise 'message aussi derrière la fenêtre' unless page.find('#message-recommandations', visible: :all).text(:all).strip.empty?
  page.assert_selector "dialog[open]#fenetre-#{fenetre}"
  focus = page.evaluate_script("document.activeElement.closest('form')?.id")
  utile = fiche(ctx).find { it.niveau_1? && it.ordre == 55 }
  raise "donnée utile à la position 55 absente en base, focus #{focus}" unless utile && focus == "donnee_utile_recommandation_#{utile.id}"

  ajoutee = ajouter_une_donnee_utile(page, ctx, fenetre)
  page.find('dialog[open]').click_button 'Fermer'
  liste = page.find("#recommandation_#{carte.id}").all('.donnees-disponibles li').map { it.text.squish }
  raise "carte : #{liste}" unless liste.any? { it.start_with?(utile.solution.libelle_admin.squish) && it.end_with?('55') } && liste.any? { it.start_with?(ajoutee) }

  Verify.evidence(DOSSIER, page, 'donnees-utiles', "focus=#{focus} ajoutee=#{ajoutee} carte=#{liste}")
end

def ajouter_une_donnee_utile(page, ctx, fenetre)
  libres = lu { Solution.where(id: ctx[:a_completer].solution.exposee_ids - fiche(ctx).map(&:solution_id)).map { it.libelle_admin.squish } }
  vide = page.find("dialog[open]#fenetre-#{fenetre}").all('fieldset').last
  proposees = vide.all('select option').map(&:text).compact_blank
  raise "choix #{proposees} pour #{libres}" unless proposees.sort == libres.sort

  vide.select proposees.first, from: 'Solution (obligatoire)'
  vide.click_button 'Ajouter'
  page.assert_selector "#message-#{fenetre} .fr-valid-text", text: proposees.first
  proposees.first
end

def integrations(page, ctx)
  carte = ctx[:a_completer]
  cible = lu { Demarche.rattachement(fiche(ctx).select(&:niveau_2?), ctx[:demarche].integrations_proposees.to_a, &:integree_id)[carte] }
    .find { !it.id.in?(Demarche.find(ctx[:demarche].id).appliquer_brouillon.integration_ids) }
  avant = page.find("#recommandation_#{carte.id}").find('h4', text: /\AIntégrations/).text
  dialog = Verify.fenetre(page, "Ajouter une intégration à #{carte.solution.libelle_admin.squish}")
  dialog.fill_in 'Filtrer les intégrations', with: I18n.transliterate(cible.libelle).scan(/[[:alnum:]]+/).join(' ') if dialog.has_field?('Filtrer les intégrations')
  dialog.find("label[for=demarche_integration_ids_#{cible.id}]").click
  dialog.click_button 'Enregistrer'
  page.assert_text 'brouillon enregistré', wait: 15
  apres = page.find("#recommandation_#{carte.id}")
  apres.assert_text cible.libelle.squish
  compte = apres.find('h4', text: /\AIntégrations/).text
  en_brouillon = lu { Demarche.find(ctx[:demarche].id).brouillon.to_h['integration_ids'].to_a.map(&:to_s) }
  raise "#{avant} puis #{compte}, brouillon #{en_brouillon}" unless compte == avant.sub(/\d+/) { (it.to_i + 1).to_s } && en_brouillon.include?(cible.id.to_s)

  Verify.evidence(DOSSIER, page, 'integrations', "avant=#{avant} apres=#{compte} cible=#{cible.libelle} brouillon_integration_ids=#{en_brouillon.size}")
end

def retirer(page, ctx)
  bouton = "Retirer #{ctx[:solution].libelle_admin}"
  attendue = Verify.question_de_suppression("Supprimer la recommandation #{ctx[:solution].libelle_admin} ?", true)
  Verify.refuser_la_suppression(page, bouton, attendue)
  page.assert_selector "#recommandation_#{ctx[:ajoutee].id}"
  page.accept_confirm(attendue) { page.click_button bouton }
  page.assert_selector '#message-recommandations .fr-valid-text', text: 'supprimé'
  page.assert_no_selector "#recommandation_#{ctx[:ajoutee].id}"
  focus = page.evaluate_script("document.activeElement.closest('#message-recommandations')?.textContent?.trim()")
  raise "focus perdu après suppression (#{Verify.focus_sur(page).inspect})" unless focus&.include?('supprimé')
  raise 'recommandation encore en base' if lu { Recommandation.exists?(ctx[:ajoutee].id) }

  Verify.evidence(DOSSIER, page, 'retiree', "confirmation=#{attendue.inspect} focus=#{focus}")
end

def page_publique(page, ctx)
  apres = cartes_publiques(page, ctx[:demarche])
  raise "page publique changée : #{ctx[:cartes].size} cartes avant, #{apres.size} après" unless apres == ctx[:cartes]

  Verify.evidence(DOSSIER, page, 'page-publique', "inchangee=true cartes=#{apres.size}")
end

def etroit(page, ctx)
  page.current_window.resize_to(375, 812)
  page.visit("/admin/demarches/#{ctx[:demarche].id}/edit")
  defilement = page.evaluate_script('document.documentElement.scrollWidth > innerWidth')
  raise 'défilement horizontal à 375 px' if defilement

  Verify.evidence(DOSSIER, page, 'etroit-375', "defilement_horizontal=#{defilement}")
ensure
  page.current_window.resize_to(1280, 1024)
end

def remettre(ctx)
  lu do
    Demarche.where(id: ctx[:demarche].id).update_all(brouillon: ctx[:brouillon])
    ctx[:demarche].recommandations.where.not(id: ctx[:avant].keys).destroy_all
    ctx[:avant].each { |id, attributs| Recommandation.where(id:).update_all(attributs) }
  end
end

Verify.drive(__FILE__) do |page|
  ctx = contexte
  ctx[:cartes] = cartes_publiques(page, ctx[:demarche])
  Verify.login(page)
  Verify.check('Cards') { cartes(page, ctx) }
  Verify.check('Modify') { modifier(page, ctx) }
  Verify.check('Error') { erreur(page) }
  Verify.check('Add') { ajouter(page, ctx) }
  Verify.check('Order') { changer_l_ordre(page, ctx) }
  Verify.check('Données utiles') { donnees_utiles(page, ctx) }
  Verify.check('Intégrations') { integrations(page, ctx) }
  Verify.check('Remove') { retirer(page, ctx) }
  Verify.check('Public page') { page_publique(page, ctx) }
  Verify.check('Narrow') { etroit(page, ctx) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  remettre(ctx) if ctx
end
