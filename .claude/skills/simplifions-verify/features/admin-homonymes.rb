require_relative '../harness'

DOSSIER = 'admin-homonymes'.freeze
NOM = 'API Impôt particulier'.freeze

def options_recommandation(page)
  page.visit('/admin/recommandations/new')
  options = page.all('#recommandation_solution_id option', text: NOM).map(&:text)
  raise "options recommandation #{options}" unless options.size == 2 && options.uniq.size == 2

  Verify.evidence(DOSSIER, page, 'recommandation', "options=#{options.join(' | ')} en_base=#{Solution.where(nom: NOM).pluck(:categorie).join(',')}")
  options
end

def options_des_selects(page)
  options = options_recommandation(page)
  page.visit('/admin/integrations/new')
  integrees = page.all('#integration_integree_id option', text: NOM).map(&:text)
  raise "options intégration #{integrees}" unless integrees == options

  Verify.evidence(DOSSIER, page, 'integration', "integree=#{integrees.join(' | ')}")
  options
end

def cases_filtrees(page, options)
  page.visit('/admin/types_acteurs/new')
  groupe = page.find('fieldset', text: 'Filtrer les solutions')
  groupe.fill_in 'Filtrer les solutions', with: 'impot particulier'
  cases = groupe.all('[data-liste-filtrable-target=element]:not(.fr-hidden) label').map(&:text)
  raise "cases #{cases}" unless cases.sort == options.sort

  Verify.evidence(DOSSIER, page, 'cases-filtrables', "cases=#{cases.join(' | ')}")
end

def categories_dans_la_liste(page)
  page.visit('/admin/solutions')
  Verify.rechercher(page, 'impot particulier')
  lignes = page.all("nav[aria-label='Liste des solutions'] li a").map { it.text.squish }.select { it.start_with?(NOM) }.map { it.delete_prefix(NOM).strip }
  categories = Solution.where(nom: NOM).map { Solution.human_attribute_name("categorie.#{it.categorie}") }
  raise "lignes #{lignes}" unless lignes.size == 2 && categories.all? { |categorie| lignes.one? { it.start_with?(categorie) } }

  lignes
end

Verify.drive(__FILE__) do |page|
  Verify.login(page)
  options = Verify.check('Selects') { options_des_selects(page) }
  Verify.check('Checkbox list') { cases_filtrees(page, options) }
  lignes = Verify.check('Categories in the list') { categories_dans_la_liste(page) }
  Verify.check('Proof') do
    Verify.evidence(DOSSIER, page, 'liste-categories', "lignes=#{lignes.join(' / ')}")
    Verify.logout(page)
  end
end
