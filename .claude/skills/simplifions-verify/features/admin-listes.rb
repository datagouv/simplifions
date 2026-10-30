require_relative '../harness'

DOSSIER = 'admin-listes'.freeze
ENTETES_SOLUTIONS = ['Id', 'Nom', 'Privée', 'Visible', 'Modifié le', 'Intégrée par'].freeze
ENTETES_INTEGRATIONS = ['Id', 'Solution', 'API ou jeu de données', 'Type d’intégration', 'Statut de l’intégration'].freeze

def lignes_affichees(page) = page.all('tbody tr').map { |ligne| ligne.all('td').map(&:text) }
def entetes(page) = page.all('thead th').map(&:text)

def solutions_page_1(page)
  Verify.rubrique(page, 'Solutions')
  page.assert_selector 'thead th', text: 'Intégrée par'
  raise "entetes #{entetes(page)}" unless entetes(page) == ENTETES_SOLUTIONS

  lignes = lignes_affichees(page).size
  raise "lignes page 1 #{lignes}" unless lignes == [Solution.count, 50].min

  Verify.evidence(DOSSIER, page, 'solutions-page-1', "solutions=#{Solution.count} lignes=#{lignes} pages=#{[(Solution.count / 50.0).ceil, 50].min}")
end

def page_2(page)
  page.click_link 'Page 2'
  premiere = Solution.order(:id).offset(50).first
  page.assert_selector 'tbody tr:first-child td', text: premiere.nom
  Verify.evidence(DOSSIER, page, 'solutions-page-2', "url=#{page.current_url.sub(%r{\Ahttps?://[^/]+}, '')} premiere=#{premiere.id}")
end

def recherche(page, integree)
  Verify.rechercher(page, integree.nom)
  noms = lignes_affichees(page).map(&:second)
  attendus = Solution.recherche(integree.nom).order(:id).limit(50).map(&:libelle_admin)
  raise "recherche #{noms} != #{attendus}" unless noms == attendus

  Verify.evidence(DOSSIER, page, 'solutions-recherche', "q=#{integree.nom} lignes=#{noms.size} en_base=#{Solution.recherche(integree.nom).count}")
end

def lien_integratrice(page, integree)
  integratrice = integree.integratrices.min_by(&:nom)
  page.within(:xpath, "//tr[td[2][normalize-space()=#{integree.libelle_admin.inspect}]]") { page.click_link integratrice.libelle_admin, exact_text: true }
  page.assert_current_path("/admin/solutions/#{integratrice.id}/edit")
  Verify.evidence(DOSSIER, page, 'integratrice-ouverte', "integree=#{integree.id} integratrice=#{integratrice.id} url=#{page.current_path}")
end

def recherche_croisee(reco) = "#{reco.demarche.nom.split.first} #{reco.solution.nom.split.last}"

def recherche_jointe(page)
  Verify.rubrique(page, 'Recommandations')
  reco = Recommandation.includes(:demarche, :solution).order(:id).first
  Verify.rechercher(page, recherche_croisee(reco))
  page.assert_selector 'tbody a', text: reco.libelle
  Verify.evidence(DOSSIER, page, 'recommandations-recherche', "q=#{page.find_field('Rechercher').value} #{lignes_et_visibilite(page)}")
end

def lignes_et_visibilite(page)
  visibles = page.all('tbody tr').map { |ligne| ligne.all('td')[2].text }.tally
  "lignes=#{lignes_affichees(page).size} visible=#{visibles}"
end

def tableau_de_bord(page)
  page.visit('/admin')
  rubriques = %w[Catalogue Référentiels].index_with { |titre| page.find('h2', text: titre).find(:xpath, 'following-sibling::ul[1]').all('a').map(&:text) }
  raise "rubriques #{rubriques}" unless rubriques['Référentiels'] == ['Fournisseurs de services', 'Vocabulaires']

  Verify.evidence(DOSSIER, page, 'accueil-rubriques', rubriques.map { |titre, liens| "#{titre}=#{liens.join('|')}" }.join(' '))
end

def une_seule_page(page)
  raise 'pagination organisations' if page.has_css?('.fr-pagination', wait: 0)

  lignes = lignes_affichees(page).size
  raise "organisations #{lignes} != #{Organisation.count}" unless lignes == Organisation.count

  lignes
end

def organisations(page)
  Verify.rubrique(page, 'Organisations')
  lignes = une_seule_page(page)
  organisation = Organisation.where.not(nom_long: [nil, '']).order(:id).first
  page.assert_selector 'tbody tr', text: "#{organisation.nom} #{organisation.nom_long}"
  Verify.evidence(DOSSIER, page, 'organisations-une-page', "lignes=#{lignes} en_base=#{Organisation.count} nom_long=#{organisation.nom_long}")
end

def ligne_attendue(integration)
  [integration.id.to_s, integration.integratrice.libelle_admin, integration.integree.libelle_admin, integration.type_libelle, integration.statut.to_s]
end

def integrations(page)
  Verify.rubrique(page, 'Intégrations')
  attendu = ligne_attendue(Integration.includes(:integratrice, :integree).order(:id).first)
  raise "entetes #{entetes(page)}" unless entetes(page) == ENTETES_INTEGRATIONS

  premiere = lignes_affichees(page).first
  raise "intégration #{premiere} != #{attendu}" unless premiere == attendu

  Verify.evidence(DOSSIER, page, 'integrations-colonnes', "premiere=#{attendu.join(' | ')}")
end

def cellule_avec_icone(page, demarche)
  cellule = page.find(:xpath, "//tbody//td[a[normalize-space()=#{demarche.nom.inspect}]]")
  icone_masquee = cellule.has_css?('[aria-hidden=true]', text: demarche.icone)
  raise "icône #{cellule.text}" unless cellule.text == "#{demarche.icone} #{demarche.nom}" && icone_masquee

  cellule.text
end

def demarches(page)
  Verify.rubrique(page, 'Démarches')
  demarche = Demarche.where.not(icone: [nil, '']).order(:id).first
  Verify.rechercher(page, demarche.nom)
  Verify.evidence(DOSSIER, page, 'demarche-icone', "demarche=#{demarche.id} cellule=#{cellule_avec_icone(page, demarche)}")
end

Verify.drive(__FILE__) do |page|
  integree = Solution.joins(:integrations_comme_integree).order(:id).first
  Verify.login(page)
  Verify.check('Columns and page 1') { solutions_page_1(page) }
  Verify.check('Page 2') { page_2(page) }
  Verify.check('Search') { recherche(page, integree) }
  Verify.check('Integrator link') { lien_integratrice(page, integree) }
  Verify.check('Joined search') { recherche_jointe(page) }
  Verify.check('Dashboard') { tableau_de_bord(page) }
  Verify.check('Organisations') { organisations(page) }
  Verify.check('Intégrations') { integrations(page) }
  Verify.check('Démarches') { demarches(page) }
  Verify.check('Proof') { Verify.logout(page) }
end
