require_relative '../harness'

DOSSIER = 'ordre-api-fournies'.freeze

def titres_fournis(page)
  page.scroll_to(page.find('#donnees-api-fournies'), align: :top)
  page.all(:xpath, "//section[.//h2[@id='donnees-api-fournies']]//*[contains(@class,'dataservice-card')]//a[1]").map { it.text.squish }
end

def lire_avant(page, solution)
  page.visit("/solutions/#{solution.slug}")
  titres_fournis(page).tap do |avant|
    Verify.evidence(DOSSIER, page, 'avant', "slug=#{solution.slug} premiere=#{avant.first} derniere=#{avant.last} nb=#{avant.size}")
  end
end

def saisir_l_ordre(page, integration, valeur)
  page.visit("/admin/integrations/#{integration.id}/edit")
  page.fill_in 'Ordre', with: valeur
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
end

def mettre_en_tete(page, solution, integration, avant)
  page.visit("/admin/solutions/#{solution.id}/edit")
  Verify.onglet(page, 'Intégrations')
  page.click_link "Modifier l’intégration #{integration.libelle}"
  page.fill_in 'Ordre', with: '1'
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  ActiveRecord::Base.uncached { Verify.evidence(DOSSIER, page, 'ordre-saisi', "ordre_en_base=#{integration.reload.ordre}") }
  page.visit("/solutions/#{solution.slug}")
  apres = titres_fournis(page)
  raise "#{integration.integree.nom} pas en tête : #{apres.first}" unless apres.first == avant.last && apres.drop(1) == avant[0...-1]

  Verify.evidence(DOSSIER, page, 'en-tete', "premiere=#{apres.first} suite_inchangee=#{apres.drop(1) == avant[0...-1]}")
end

def vider(page, solution, integration, avant)
  saisir_l_ordre(page, integration, '')
  page.visit("/solutions/#{solution.slug}")
  raise "ordre non rétabli : #{titres_fournis(page)}" unless titres_fournis(page) == avant

  ActiveRecord::Base.uncached { Verify.evidence(DOSSIER, page, 'defait', "ordre_en_base=#{integration.reload.ordre.inspect} ordre_initial=true") }
end

Verify.drive(__FILE__) do |page|
  solution = Solution.visibles.where.not(slug: nil).max_by { it.exposees.visibles.sur_datagouv.count }
  api = solution.api_fournies_dans_l_ordre.visibles.sur_datagouv.to_a.last
  integration = solution.integrations_qu_elle_expose.find_by!(integree: api)
  ordre = integration.ordre
  avant = Verify.check('Avant') { lire_avant(page, solution) }
  Verify.login(page)
  Verify.check('Rang') { mettre_en_tete(page, solution, integration, avant) }
  Verify.check('Vide') { vider(page, solution, integration, avant) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  ActiveRecord::Base.uncached { integration.reload.update_columns(ordre:) if integration && integration.reload.ordre != ordre }
end
