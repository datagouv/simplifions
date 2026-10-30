require_relative '../harness'

DOSSIER = 'admin-integrations-en-ligne'.freeze
INTEGRE = 'la nouvelle ligne de « Ce qu’elle intègre »'.freeze
L_INTEGRENT = 'la nouvelle ligne de « Solutions qui l’intègrent »'.freeze

def api_non_integree(solution)
  Solution.categorie_api.where.not(id: [solution.id, *solution.integrations_comme_integratrice.pluck(:integree_id)]).order(:id).first
end

def integratrice_absente(solution)
  Solution.where.not(categorie: 'api').where.not(id: [solution.id, *solution.integrations_comme_integree.pluck(:integratrice_id)]).order(:id).first
end

def contexte
  solution = Solution.visibles.where.not(categorie: 'api').max_by { it.integrations_comme_integratrice.count }
  integration = solution.integrations_comme_integratrice.par_libelle_admin_de(:integree).first
  { solution:, integration:, statut: integration.statut, nom: "l’intégration #{integration.libelle}",
    api: api_non_integree(solution), integratrice: integratrice_absente(solution) }
end

def compter(solution)
  ActiveRecord::Base.uncached { [solution.integrations_comme_integratrice.count, solution.integrations_comme_integree.count] }
end

def onglet_integrations(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit?onglet=integrations")
end

def changer_le_statut(page, ctx)
  page.visit("/admin/solutions/#{ctx[:solution].id}/edit")
  Verify.onglet(page, 'Intégrations')
  page.select (Integration::STATUTS - [ctx[:statut]]).first, from: "Statut de #{ctx[:nom]}"
  raise 'la ligne a marqué la fiche' unless Verify.enregistrer_desactive?(page)
end

def modifier_le_statut(page, ctx)
  changer_le_statut(page, ctx)
  page.click_button "Enregistrer #{ctx[:nom]}"
  page.assert_selector '#message-integrations .fr-valid-text', text: 'enregistré'
  focus = Verify.focus_sur(page)
  raise "focus perdu après enregistrement (#{focus.inspect})" unless focus == "enregistrer_integration_#{ctx[:integration].id}"

  preuve_du_statut(page, ctx)
end

def preuve_du_statut(page, ctx)
  ActiveRecord::Base.uncached do
    Verify.evidence(DOSSIER, page, 'ligne-modifiee', "statut_avant=#{ctx[:statut].inspect} statut_en_base=#{ctx[:integration].reload.statut.inspect} " \
                                                     "focus=#{Verify.focus_sur(page)} fiche_grisee=#{Verify.enregistrer_desactive?(page)} url=#{page.current_path}")
  end
end

def erreur_elle_meme(page, ctx)
  page.select ctx[:solution].libelle_admin, from: "API ou jeu de données de #{INTEGRE} (obligatoire)"
  page.select 'Intégrée', from: "Type d’intégration de #{INTEGRE} (obligatoire)"
  page.click_button "Ajouter #{INTEGRE}"
  erreur = page.find('#erreurs_integree_integration', text: 'elle-même')
  en_base = compter(ctx[:solution])
  raise "créée malgré l'erreur : #{en_base} au lieu de #{ctx[:avant]}" unless en_base == ctx[:avant]

  preuve_de_l_erreur(page, erreur, en_base, ctx[:avant])
end

def preuve_de_l_erreur(page, erreur, en_base, avant)
  Verify.evidence(DOSSIER, page, 'erreur-ligne', "erreur=#{erreur.text} focus=#{Verify.focus_sur(page)} en_base=#{en_base} avant=#{avant} " \
                                                 "decrit_par=#{page.find('tr#integree_integration button')['aria-describedby']}")
end

def ajouter_une_ligne(page, ligne, choix)
  choix.each { |champ, valeur| page.select valeur, from: "#{champ} de #{ligne} (obligatoire)" }
  page.click_button "Ajouter #{ligne}"
  page.assert_selector '#message-integrations .fr-valid-text', text: choix.values.first
end

def ajouter_l_integree(page, ctx)
  ajouter_une_ligne(page, INTEGRE, 'API ou jeu de données' => ctx[:api].libelle_admin)
  ctx[:integree_creee] = ActiveRecord::Base.uncached { ctx[:solution].integrations_comme_integratrice.find_by!(integree: ctx[:api]) }
  page.assert_selector "tr#integration_#{ctx[:integree_creee].id}"
end

def ajouter_l_integratrice(page, ctx)
  ajouter_une_ligne(page, L_INTEGRENT, 'Solution' => ctx[:integratrice].libelle_admin, 'Type d’intégration' => 'Fournie')
  ctx[:integratrice_creee] = ActiveRecord::Base.uncached { ctx[:solution].integrations_comme_integree.find_by!(integratrice: ctx[:integratrice]) }
  page.assert_selector "tr#integration_#{ctx[:integratrice_creee].id}"
end

def ajouter(page, ctx)
  ajouter_l_integree(page, ctx)
  ajouter_l_integratrice(page, ctx)
  preuve_des_ajouts(page, ctx)
end

def preuve_des_ajouts(page, ctx)
  vides = %w[integree integratrice].map { |cote| page.find("tr##{cote}_integration select[name='integration[#{cote}_id]']").value }
  types = [ctx[:integree_creee].type_integration, ctx[:integratrice_creee].type_integration]
  Verify.evidence(DOSSIER, page, 'ajoutees', "en_base=#{compter(ctx[:solution])} avant=#{ctx[:avant]} lignes_vides=#{vides.inspect} types=#{types}")
end

def mesurer_a(page, ctx, largeur)
  page.current_window.resize_to(largeur, 1024)
  onglet_integrations(page, ctx[:solution])
  defilement = page.evaluate_script("[...document.querySelectorAll('#onglet-integrations-panneau .fr-table__content')].map(c => [c.scrollWidth, c.clientWidth])")
  raise "tableaux à #{largeur} px : #{defilement}" if defilement.any? { |defilable, visible| defilable > visible }

  selects = page.evaluate_script("[...document.querySelector('tr#integration_#{ctx[:integration].id}').querySelectorAll('select')].map(s => s.clientWidth)")
  raise "selects trop étroits à #{largeur} px (solution, type, statut) : #{selects}" if selects.first < 150 || selects.last < 180

  Verify.evidence(DOSSIER, page, "largeur-#{largeur}", "tableaux_defilable_visible=#{defilement} selects_solution_type_statut=#{selects}")
end

def largeurs(page, ctx)
  [1280, 1024].each { mesurer_a(page, ctx, it) }
  page.current_window.resize_to(375, 812)
  onglet_integrations(page, ctx[:solution])
  Verify.evidence(DOSSIER, page, 'etroit-375', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
end

def refuser_puis_supprimer(page, integration, poubelle)
  page.dismiss_confirm("#{poubelle} ?") { page.click_button poubelle }
  page.assert_selector "tr#integration_#{integration.id}"
  raise 'refuser la confirmation a supprimé' unless ActiveRecord::Base.uncached { Integration.exists?(integration.id) }

  page.accept_confirm("#{poubelle} ?") { page.click_button poubelle }
  page.assert_selector '#message-integrations .fr-valid-text', text: 'supprimé'
  page.assert_no_selector "tr#integration_#{integration.id}"
end

def supprimer_depuis_la_ligne(page, integration)
  refuser_puis_supprimer(page, integration, "Supprimer l’intégration #{integration.libelle}")
  focus = page.evaluate_script("document.activeElement.closest('#message-integrations')?.textContent?.trim()")
  raise "focus perdu après suppression (#{Verify.focus_sur(page).inspect})" unless focus&.include?('supprimé')

  focus
end

def remettre_le_statut(page, ctx)
  page.find_field("Statut de #{ctx[:nom]}").find("option[value='#{ctx[:statut]}']").select_option
  page.click_button "Enregistrer #{ctx[:nom]}"
  page.assert_selector '#message-integrations .fr-valid-text', text: 'enregistré'
end

def defaire(page, ctx)
  onglet_integrations(page, ctx[:solution])
  ctx[:focus] = [ctx[:integree_creee], ctx[:integratrice_creee]].map { supprimer_depuis_la_ligne(page, it) }
  remettre_le_statut(page, ctx)
  etat_revenu(ctx)
end

def etat_revenu(ctx)
  en_base = compter(ctx[:solution])
  raise "intégrations #{en_base} au lieu de #{ctx[:avant]}" unless en_base == ctx[:avant]

  statut = ActiveRecord::Base.uncached { ctx[:integration].reload.statut }
  raise "statut #{statut.inspect} au lieu de #{ctx[:statut].inspect}" unless statut == ctx[:statut]
end

def preuve(page, ctx)
  statut = ActiveRecord::Base.uncached { ctx[:integration].reload.statut }
  Verify.evidence(DOSSIER, page, 'defait', "url=#{page.current_path} en_base=#{compter(ctx[:solution])} avant=#{ctx[:avant]} " \
                                           "statut=#{statut.inspect} focus=#{ctx[:focus]}")
  Verify.logout(page)
end

def nettoyer(ctx)
  ActiveRecord::Base.uncached do
    Integration.where(id: [ctx[:integree_creee]&.id, ctx[:integratrice_creee]&.id].compact).destroy_all
    ctx[:integration].reload.update!(statut: ctx[:statut]) if ctx[:integration].reload.statut != ctx[:statut]
  end
end

def cellule_integree_par(page, bouquet)
  entetes = page.all('thead th').map(&:text)
  ligne = page.find(:xpath, "//tbody/tr[td[1][normalize-space()='#{bouquet.id}']]")
  ligne.all('td')[entetes.index('Intégrée par')].all('a').map(&:text)
end

def liste_du_bouquet(page, bouquet)
  attendus = bouquet.integree_par.map(&:libelle_admin).sort_by(&:downcase)
  Verify.login(page)
  Verify.rubrique(page, 'Solutions')
  Verify.rechercher(page, bouquet.nom)
  cellule = cellule_integree_par(page, bouquet)
  raise "Intégrée par #{cellule.size} != #{attendus.size}" unless cellule == attendus

  Verify.evidence(DOSSIER, page, 'bouquet-integree-par', "bouquet=#{bouquet.id} integree_par=#{cellule.size} en_base=#{attendus.size} premieres=#{cellule.first(3)}")
end

def onglet_du_bouquet(page, bouquet)
  page.visit("/admin/solutions/#{bouquet.id}/edit")
  Verify.onglet(page, 'Intégrations')
  titre = page.find('[role=tab][aria-selected=true]').text
  lignes = bouquet.integrations_de_ses_api.count
  total = bouquet.integrations_comme_integratrice.count + bouquet.integrations_comme_integree.count + lignes
  raise "onglet #{titre} != #{total}" unless titre == "Intégrations (#{total})"

  lignes_via(page, titre, lignes)
end

def lignes_via(page, titre, lignes)
  items = page.all('#onglet-integrations-panneau ul li', visible: :all)
  raise "lignes via #{items.size} != #{lignes}" unless items.size == lignes && items.all? { it.text(:all).include?(' — via ') }

  page.scroll_to(items.first, align: :center)
  Verify.evidence(DOSSIER, page, 'bouquet-lignes-via', "onglet=#{titre} lignes_via=#{items.size} premiere=#{items.first.text(:all)}")
  items
end

def lien_du_bouquet(page, bouquet, items)
  premiere = items.first.text(:all)
  items.first.click_link 'Voir la fiche'
  page.assert_no_current_path("/admin/solutions/#{bouquet.id}/edit")
  ouverte = Solution.find(page.current_path[%r{/admin/solutions/(\d+)/edit}, 1])
  raise "fiche ouverte #{ouverte.libelle_admin} pas dans #{premiere}" unless bouquet.exposees.include?(ouverte)

  Verify.evidence(DOSSIER, page, 'bouquet-fiche-via', "lignes_via=#{items.size} api_ouverte=#{ouverte.libelle_admin}")
end

def preuve_du_bouquet(page)
  manquantes = %w[bouquet-integree-par bouquet-lignes-via bouquet-fiche-via].reject { Verify::ROOT.join(DOSSIER, "#{Verify.browser}-#{it}.png").exist? }
  raise "captures manquantes : #{manquantes}" if manquantes.any?

  Verify.logout(page)
end

Verify.drive(__FILE__) do |page|
  ctx = contexte
  ctx[:avant] = compter(ctx[:solution])
  Verify.login(page)
  Verify.check('Row') { modifier_le_statut(page, ctx) }
  Verify.check('Error') { erreur_elle_meme(page, ctx) }
  Verify.check('Add') { ajouter(page, ctx) }
  Verify.check('Width') { largeurs(page, ctx) }
  Verify.check('Undo') { defaire(page, ctx) }
  Verify.check('Proof') { preuve(page, ctx) }
  bouquet = Solution.all.max_by { it.integrations_de_ses_api.size }
  Verify.check('Bouquet list') { liste_du_bouquet(page, bouquet) }
  items = Verify.check('Bouquet tab') { onglet_du_bouquet(page, bouquet) }
  Verify.check('Bouquet link') { lien_du_bouquet(page, bouquet, items) }
  Verify.check('Bouquet proof') { preuve_du_bouquet(page) }
ensure
  nettoyer(ctx) if ctx
end
