require_relative '../harness'

DOSSIER = 'admin-saisie-solution'.freeze
IMAGE = 'app/assets/images/articles/api-franceconnectees-donnees-personnelles.png'.freeze

def integrations_liees(page)
  Verify.onglet(page, 'Intégrations')
  page.all('#onglet-integrations-panneau h2').to_h do |titre|
    selects = page.find("table[aria-labelledby='#{titre[:id]}']").all('tbody tr td:first-child select')
    [titre.text, selects.filter_map { it.all('option[selected]', visible: :all).first&.text }]
  end
end

def elements_lies(page)
  lies = integrations_liees(page)
  Verify.onglet(page, 'Recommandée dans')
  lies.merge('Recommandée dans' => page.find('#onglet-recommandee-dans-panneau').all('a').map(&:text)).reject { |_, liens| liens.empty? }
end

def types_coches(page) = page.evaluate_script(%q([...document.querySelectorAll('input[name="solution[types_solution][]"]:checked')].map((c) => c.value)))

def types_en_base(solution) = ActiveRecord::Base.uncached { Solution.find(solution.id).types_solution }

def creer_solution(nom, api, demarche)
  solution = Solution.new(nom:, categorie: 'brique_logicielle', legende_image: 'Écran de vérification',
    organisations: [Organisation.where(public_ou_prive: 'Public').order(:id).first])
  solution.image.attach(io: Rails.root.join(IMAGE).open, filename: 'verif.png')
  solution.save!
  Integration.create!(integratrice: solution, integree: api, type_integration: 'consomme')
  Recommandation.create!(demarche:, solution:, niveau: :niveau_2)
  solution
end

def fiche(page, solution, attendu)
  page.visit("/admin/solutions/#{solution.id}/edit")
  legende = page.find_field('Légende de l’image')
  aide = page.find('label[for=solution_retirer_image] .fr-hint-text').text
  lies = elements_lies(page)
  raise "legende=#{legende.tag_name}/#{legende[:type]} aide=#{aide} lies=#{lies}" unless
    legende[:type] == 'text' && aide == 'L’image sera retirée à l’enregistrement.' && lies == attendu

  Verify.evidence(DOSSIER, page, 'fiche', "legende=#{legende.tag_name}[type=#{legende[:type]}] aide_retirer=#{aide} lies=#{lies}")
end

def integratrices_en_base(api)
  api.integrations_comme_integree.par_libelle_admin_de(:integratrice).map { |integration| integration.integratrice.libelle_admin.squish }
end

def autre_cote(page, api, solution)
  page.visit("/admin/solutions/#{api.id}/edit")
  page.assert_selector 'h1', text: api.libelle_admin
  integratrices = elements_lies(page)['Solutions qui l’intègrent']
  base = integratrices_en_base(api)
  raise "integratrices #{integratrices} != #{base}" unless integratrices == base && integratrices.include?(solution.libelle_admin)

  Verify.evidence(DOSSIER, page, 'api-liee', "url=#{page.current_path} integratrices_page=#{integratrices.size} base=#{base.size} inclut_verif=true")
end

def neuf_types(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  libelles = page.all('#solution_types_solution .fr-label', visible: :all).map { |label| label[:textContent].strip }
  raise "cases #{libelles}" unless libelles == Solution::TYPES_SOLUTION

  libelles
end

def cocher_deux_types(page, libelles)
  page.check 'Portail agent', allow_label_click: true
  page.check "Hub d'échange", allow_label_click: true
  page.find('#solution_types_solution input[value="Portail agent"]', visible: :all).execute_script('this.focus()')
  page.send_keys(:tab)
  focus = page.evaluate_script('document.activeElement.value')
  suivant = libelles[libelles.index('Portail agent') + 1]
  raise "Tab après Portail agent sur #{focus.inspect}, attendu #{suivant}" unless focus == suivant

  Verify.evidence(DOSSIER, page, 'cases-cochees', "cases=#{libelles.size} cochees=#{types_coches(page)} tab_apres_portail_agent=#{focus}")
end

def enregistrer_types(page, solution, etape, attendu)
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  raise "base #{etape} #{types_en_base(solution)}" unless types_en_base(solution) == attendu

  Verify.evidence(DOSSIER, page, etape, "base=#{types_en_base(solution)} cochees_page=#{types_coches(page)}")
end

def etroit(page, solution)
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/solutions/#{solution.id}/edit")
  Verify.evidence(DOSSIER, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  api = Solution.visibles.categorie_api.joins(:integrations_comme_integree).distinct.order(:id).first
  demarche = Demarche.visibles.order(:id).first
  solution = creer_solution(nom, api, demarche)
  Verify.login(page)
  Verify.check('Fiche') { fiche(page, solution, { 'Ce qu’elle intègre' => [api.libelle_admin], 'Recommandée dans' => [demarche.nom] }) }
  Verify.check('Other side') { autre_cote(page, api, solution) }
  Verify.check('Types') do
    cocher_deux_types(page, neuf_types(page, solution))
    enregistrer_types(page, solution, 'enregistre', ['Portail agent', "Hub d'échange"])
    page.uncheck 'Portail agent', allow_label_click: true
    enregistrer_types(page, solution, 'decoche', ["Hub d'échange"])
  end
  Verify.check('Proof') do
    etroit(page, solution)
    Verify.logout(page)
  end
ensure
  Solution.where(nom:).destroy_all
end
