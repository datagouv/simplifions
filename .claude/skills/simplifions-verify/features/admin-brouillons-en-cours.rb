require_relative '../harness'

DOSSIER = 'admin-brouillons-en-cours'.freeze

def en_base = ActiveRecord::Base.uncached { [Demarche.en_brouillon.count, Solution.en_brouillon.count] }

def liste_filtree(page)
  Verify.rubrique(page, 'Démarches')
  page.click_link "Brouillons en cours (#{en_base.first})"
  page.assert_current_path('/admin/demarches?brouillons=1')
end

def toutes_en_brouillon(page, colonne = 2)
  cellules = page.all('tbody tr').map { it.all('td')[colonne].text }
  raise "lignes sans Brouillon #{cellules}" unless cellules.all? { it.downcase.include?('brouillon') }

  cellules.size
end

def demarches_filtrees(page, nom)
  liste_filtree(page)
  total = en_base.first
  page.assert_selector '[role=status]', text: "#{total} ligne"
  page.assert_selector 'tbody a', text: nom
  lignes = toutes_en_brouillon(page)
  Verify.evidence(DOSSIER, page, 'demarches-filtrees', "lignes=#{lignes} statut=#{page.find('[role=status]').text} en_base=#{total}")
  page.click_link 'Voir toutes les lignes'
  page.assert_current_path('/admin/demarches')
end

def recherche_filtree(page, nom)
  page.click_link "Brouillons en cours (#{en_base.first})"
  Verify.rechercher(page, 'Vérif verify-map')
  page.assert_current_path(/brouillons=1/, url: true)
  noms = page.all('tbody tr').map { it.all('td')[1].text }
  raise "recherche #{noms}" unless noms == [nom]

  toutes_en_brouillon(page)
  Verify.evidence(DOSSIER, page, 'recherche-filtree', "url=#{URI(page.current_url).request_uri} lignes=#{noms}")
end

def solutions_filtrees(page, nom)
  Verify.rubrique(page, 'Solutions')
  total = en_base.last
  page.click_link "Brouillons en cours (#{total})"
  page.assert_current_path('/admin/solutions?brouillons=1')
  page.assert_selector 'tbody tr', text: nom
  lignes = toutes_en_brouillon(page, 3)
  Verify.evidence(DOSSIER, page, 'solutions-filtrees', "lignes=#{lignes} en_base=#{total}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Demarche.create!(nom:, slug:, visible: true, brouillon: { 'nom' => "#{nom} v2" })
  Solution.create!(nom:, categorie: 'api', visible: true, brouillon: { 'nom' => "#{nom} v2" })
  Verify.login(page)
  Verify.check('Filtered démarches') { demarches_filtrees(page, nom) }
  Verify.check('Search keeps the filter') { recherche_filtree(page, nom) }
  Verify.check('Filtered solutions') { solutions_filtrees(page, nom) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom:).destroy_all
  Solution.where(nom:).destroy_all
end
