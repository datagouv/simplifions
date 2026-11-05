require_relative '../harness'

DOSSIER = 'admin-brouillons-en-cours'.freeze

def en_base = ActiveRecord::Base.uncached { [Demarche.en_brouillon.count, Solution.en_brouillon.count] }

def liste_filtree(page)
  Verify.rubrique(page, 'Démarches')
  page.select 'En brouillon', from: 'État'
  page.click_button 'Filtrer'
  page.assert_current_path(/etat=brouillons/, url: true)
end

LISTE = "nav[aria-label='Liste des %s']".freeze

def lignes_de_la_liste(page, des) = page.all("#{format(LISTE, des)} li a")

def toutes_en_brouillon(page, des)
  lignes = lignes_de_la_liste(page, des).map(&:text)
  raise "lignes sans Brouillon #{lignes}" unless lignes.all? { it.downcase.include?('brouillon') }

  lignes.size
end

def comptage(page, des) = page.find("#{format(LISTE, des)} [role=status]").text

def demarches_filtrees(page, nom)
  liste_filtree(page)
  total = en_base.first
  page.assert_selector "#{format(LISTE, 'démarches')} [role=status]", text: "#{total} démarche"
  page.assert_selector "#{format(LISTE, 'démarches')} li a", text: nom
  raise "état #{page.find_field('État').value}" unless page.find_field('État').value == 'brouillons'

  lignes = toutes_en_brouillon(page, 'démarches')
  raise "lignes #{lignes} != #{total}" unless lignes == total

  Verify.evidence(DOSSIER, page, 'demarches-filtrees', "lignes=#{lignes} statut=#{comptage(page, 'démarches')} en_base=#{total}")
  raise 'Voir toutes les lignes subsiste' if page.has_link?('Voir toutes les lignes', wait: 0)
end

def recherche_filtree(page, nom)
  Verify.rechercher(page, 'Vérif verify-map')
  page.assert_current_path(/etat=brouillons/, url: true)
  noms = lignes_de_la_liste(page, 'démarches').map { it.find('.fr-text--bold').text }
  raise "recherche #{noms}" unless noms == [nom]

  toutes_en_brouillon(page, 'démarches')
  Verify.evidence(DOSSIER, page, 'recherche-filtree', "url=#{URI(page.current_url).request_uri} lignes=#{noms}")
end

def solutions_filtrees(page, nom)
  Verify.rubrique(page, 'Solutions')
  total = en_base.last
  page.select 'En brouillon', from: 'État'
  page.click_button 'Filtrer'
  page.assert_current_path(/etat=brouillons/, url: true)
  page.assert_selector "#{format(LISTE, 'solutions')} li a", text: nom
  lignes = toutes_en_brouillon(page, 'solutions')
  raise "lignes #{lignes} != #{total}" unless lignes == total

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
