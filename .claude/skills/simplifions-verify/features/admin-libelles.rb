require_relative '../harness'

DOSSIER = 'admin-libelles'.freeze

def libelles_de(page)
  page.evaluate_script(<<~JS)
    Array.from(document.querySelectorAll('form[data-controller="formulaire-modifie"] :is(label, legend)'))
      .map((e) => Array.from(e.childNodes).filter((n) => n.nodeType === 3).map((n) => n.textContent).join('').trim())
      .filter(Boolean)
  JS
end

def recommandation(page)
  reco = Recommandation.niveau_1.order(:id).first!
  type_de_recommandation(page, reco)
  libelles_de(page).first(6).tap { Verify.evidence(DOSSIER, page, 'recommandation', "reco=#{reco.id} niveau=#{reco.niveau} ordre=#{it.join(' | ')}") }
end

def type_de_recommandation(page, reco)
  page.visit("/admin/recommandations/#{reco.id}/edit")
  page.assert_selector :select, 'Type de recommandation', selected: 'Donnée utile (API ou jeu de données)'
  page.find('label', text: 'Type de recommandation').assert_text 'Solution recommandée : carte sur la page du cas d’usage'
  page.scroll_to(page.find_field('Type de recommandation'), align: :center)
end

def categorie_de_solution(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  page.assert_selector :field, 'Identifiant data.gouv', with: solution.uid_datagouv
  categorie = Solution.human_attribute_name("categorie.#{solution.categorie}")
  page.assert_selector :select, 'Catégorie de solution', selected: categorie
  page.scroll_to(page.find_field('Identifiant data.gouv'), align: :center)
  categorie
end

def solution(page)
  solution = Solution.where.not(uid_datagouv: [nil, '']).where.not(categorie: nil).order(:id).first!
  categorie = categorie_de_solution(page, solution)
  libelles_de(page).first(5).tap { Verify.evidence(DOSSIER, page, 'solution', "solution=#{solution.id} categorie=#{solution.categorie}→#{categorie} ordre=#{it.join(' | ')}") }
end

def integration(page)
  integration = Integration.consomme.order(:id).first!
  page.visit("/admin/integrations/#{integration.id}/edit")
  page.assert_selector :select, 'Type d’intégration', selected: 'Intégrée'
  libelles_de(page).first(4).tap { Verify.evidence(DOSSIER, page, 'integration', "integration=#{integration.id} type=#{integration.type_integration} ordre=#{it.join(' | ')}") }
end

def aucun_formulaire_vide(ordres)
  vides = ordres.select { |_, libelles| libelles.empty? }.keys
  raise "aucun libellé lu sur #{vides}" if vides.any?
end

def ordre(page, ordres)
  demarche = Demarche.order(:id).first!
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector :field, 'Mots-clés'
  ordres[:demarche] = libelles_de(page).first(8)
  aucun_formulaire_vide(ordres)
  Verify.evidence(DOSSIER, page, 'demarche', "demarche=#{demarche.id} ordre=#{ordres[:demarche].join(' | ')}")
end

Verify.drive(__FILE__) do |page|
  Verify.login(page)
  ordres = Verify.check('Values') { { recommandation: recommandation(page), solution: solution(page), integration: integration(page) } }
  Verify.check('Order') { ordre(page, ordres) }
  Verify.check('Proof') { Verify.logout(page) }
end
