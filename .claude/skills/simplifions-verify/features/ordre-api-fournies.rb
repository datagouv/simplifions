require_relative '../harness'

DOSSIER = 'ordre-api-fournies'.freeze

def titres_fournis(page)
  page.scroll_to(page.find('#donnees-api-fournies'), align: :top)
  page.all(:xpath, "//section[.//h2[@id='donnees-api-fournies']]//*[contains(@class,'dataservice-card')]//a[1]").map { it.text.squish }
end

def ids_dans_l_ordre(solution)
  ActiveRecord::Base.uncached { solution.integrations_qu_elle_expose.dans_l_ordre_public.pluck(:id) }
end

def ids_publics(solution)
  ActiveRecord::Base.uncached { solution.integrations_qu_elle_expose.dans_l_ordre_public.merge(Solution.visibles).merge(Solution.sur_datagouv).pluck(:id) }
end

def ordres(solution)
  ActiveRecord::Base.uncached { solution.integrations_qu_elle_expose.pluck(:id, :ordre).to_h }
end

def lire_avant(page, ctx)
  page.visit("/solutions/#{ctx[:solution].slug}")
  titres_fournis(page).tap do |avant|
    raise "#{avant.size} cartes pour #{ctx[:publics].size} intégrations" unless avant.size == ctx[:publics].size

    ctx[:titres] = ctx[:publics].zip(avant).to_h
    Verify.evidence(DOSSIER, page, 'avant', "slug=#{ctx[:solution].slug} premiere=#{avant.first} derniere=#{avant.last} nb=#{avant.size} ordres_nil=#{ctx[:ordres].values.count(nil)}")
  end
end

def lignes_du_tableau(page)
  page.all('#lignes-fournies tr[data-deplacement]').map { it[:id][/\d+/].to_i }
end

def ouvrir_l_onglet(page, ctx)
  page.visit("/admin/solutions/#{ctx[:solution].id}/edit")
  Verify.onglet(page, 'API fournies')
  page.assert_selector '#onglet-api-fournies-panneau h2', text: 'API fournies'
end

def onglet_dans_l_ordre(page, ctx)
  ouvrir_l_onglet(page, ctx)
  lignes = lignes_du_tableau(page)
  raise "tableau #{lignes.first(5)} au lieu de #{ctx[:ids].first(5)}" unless lignes == ctx[:ids]

  titre = page.find('[role=tab][aria-selected=true]').text
  raise "onglet #{titre}" unless titre == "API fournies (#{ctx[:ids].size})"
  raise 'poignée manquante' unless page.all('#lignes-fournies [data-poignee]', visible: :all).size == ctx[:ids].size

  Verify.evidence(DOSSIER, page, 'onglet', "onglet=#{titre} lignes=#{lignes.size} premieres=#{lignes.first(3)} base=#{ctx[:ids].first(3)}")
end

def attendre_le_message(page, integration, position)
  page.assert_selector '#message-integrations .fr-valid-text', text: "« #{integration.libelle} » déplacée en position #{position}."
end

def clavier(page, ctx)
  ouvrir_l_onglet(page, ctx)
  bouge = Integration.find(ctx[:ids][4])
  ligne = "tr#integration_#{bouge.id}"
  page.find("#{ligne} button", text: "Monter l’intégration #{bouge.libelle}", visible: :all).send_keys(:enter)
  attendre_le_message(page, bouge, 4)
  focus = page.evaluate_script("(() => { const b = document.activeElement; return [b.closest('tr')?.id, b.value] })()")
  raise "focus #{focus}" unless focus.first == "integration_#{bouge.id}" && %w[monter descendre].include?(focus.last)

  ctx[:ids] = ctx[:ids].dup.tap { it[3], it[4] = it[4], it[3] }
  raise "ordre en base #{ids_dans_l_ordre(ctx[:solution]).first(6)}" unless ids_dans_l_ordre(ctx[:solution]) == ctx[:ids]
  raise 'rangs non renumérotés' unless ordres(ctx[:solution]).values.sort == (1..ctx[:ids].size).to_a

  Verify.evidence(DOSSIER, page, 'clavier', "message=position_4 focus=#{focus} base=#{ctx[:ids].first(6)} ordre=#{ordres(ctx[:solution])[bouge.id]}")
end

def poignees(page, ctx)
  [3, 1].map { page.find("tr#integration_#{ctx[:ids][it]} [data-poignee]", visible: :all) }
end

def glisser_par_capybara(page, ctx) = poignees(page, ctx).then { |source, cible| source.drag_to(cible) }

def glisser_par_actions(page, ctx)
  source, cible = poignees(page, ctx)
  page.driver.browser.action.click_and_hold(source.native).move_to(cible.native).move_by(0, -5).release.perform
end

def glisser(page, ctx)
  ouvrir_l_onglet(page, ctx)
  bouge = Integration.find(ctx[:ids][3])
  methode = %i[glisser_par_capybara glisser_par_actions].find do |nom|
    ouvrir_l_onglet(page, ctx)
    send(nom, page, ctx)
    page.has_selector?('#message-integrations .fr-valid-text', text: /déplacée en position \d+\./, wait: 5)
  end
  raise 'glisser-déposer sans effet (drag_to et actions Selenium)' unless methode

  verifier_le_glisser(page, ctx, bouge, methode)
end

def verifier_le_glisser(page, ctx, bouge, methode)
  en_base = ids_dans_l_ordre(ctx[:solution])
  position = en_base.index(bouge.id) + 1
  raise "ligne glissée toujours en position 4 : #{en_base.first(6)}" unless position < 4
  raise "autres lignes déplacées : #{en_base.first(6)}" unless en_base - [bouge.id] == ctx[:ids] - [bouge.id]

  attendre_le_message(page, bouge, position)
  raise "tableau #{lignes_du_tableau(page).first(6)} base #{en_base.first(6)}" unless lignes_du_tableau(page) == en_base

  ctx[:ids] = en_base
  Verify.evidence(DOSSIER, page, 'glisser', "methode=#{methode} message=position_#{position} base=#{en_base.first(6)} ordre=#{ordres(ctx[:solution])[bouge.id]}")
end

def apres_rechargement(page, ctx)
  ouvrir_l_onglet(page, ctx)
  lignes = lignes_du_tableau(page)
  raise "tableau rechargé #{lignes.first(6)}" unless lignes == ctx[:ids]

  page.visit("/solutions/#{ctx[:solution].slug}")
  public = titres_fournis(page)
  attendu = ids_publics(ctx[:solution]).map { ctx[:titres].fetch(it) }
  raise "page publique #{public.first(4)} au lieu de #{attendu.first(4)}" unless public == attendu
  raise 'ordre public inchangé' if public == ctx[:titres].values

  Verify.evidence(DOSSIER, page, 'rechargement', "premieres=#{public.first(3)} tableau=#{lignes.first(3)}")
end

def lecture_seule(page, ctx)
  bouge = Integration.find(ctx[:ids][1])
  page.visit("/admin/integrations/#{bouge.id}/edit")
  page.assert_text 'Ordre : 2'
  raise 'champ Ordre présent' if page.has_field?('Ordre', wait: 0)

  page.click_link "Ranger les API fournies de #{ctx[:solution].libelle_admin}"
  page.assert_current_path(/\A\/admin\/solutions\/#{ctx[:solution].id}\/edit\?.*onglet=api-fournies/, url: false)
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AAPI fournies/
  Verify.evidence(DOSSIER, page, 'lecture-seule', "ordre_affiche=2 url=#{page.current_path}")
end

def defaire(page, ctx)
  ActiveRecord::Base.uncached { ctx[:ordres].each { |id, ordre| Integration.where(id:).update_all(ordre:) } }
  raise 'ordres non rétablis' unless ordres(ctx[:solution]) == ctx[:ordres]

  page.visit("/solutions/#{ctx[:solution].slug}")
  public = titres_fournis(page)
  raise "ordre public non rétabli #{public.first(4)}" unless public == ctx[:titres].values

  Verify.evidence(DOSSIER, page, 'defait', "ordres_nil=#{ordres(ctx[:solution]).values.count(nil)} public_identique=true")
end

Verify.drive(__FILE__) do |page|
  solution = Solution.visibles.where.not(slug: nil).max_by { it.exposees.visibles.sur_datagouv.count }
  ctx = { solution:, ids: ids_dans_l_ordre(solution), publics: ids_publics(solution), ordres: ordres(solution) }
  Verify.check('Avant') { lire_avant(page, ctx) }
  Verify.login(page)
  Verify.check('Tab') { onglet_dans_l_ordre(page, ctx) }
  Verify.check('Keyboard') { clavier(page, ctx) }
  Verify.check('Drag') { glisser(page, ctx) }
  Verify.check('Reload') { apres_rechargement(page, ctx) }
  Verify.check('Read-only') { lecture_seule(page, ctx) }
  Verify.check('Undo') { defaire(page, ctx) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  ActiveRecord::Base.uncached { ctx[:ordres].each { |id, ordre| Integration.where(id:).where.not(ordre:).update_all(ordre:) } } if ctx
end
