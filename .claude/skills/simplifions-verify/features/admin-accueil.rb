require_relative '../harness'

DOSSIER = 'admin-accueil'.freeze

def zone(page, titre) = page.find('section', text: titre, match: :first)

def catalogue(page)
  page.visit('/admin')
  page.assert_selector 'h1', text: 'Bonjour'
  lignes = zone(page, 'Catalogue').all('li').map { it.text.squish }
  nombres = ActiveRecord::Base.uncached { [Demarche.count, Demarche.visibles.count, Solution.count, Solution.visibles.count, Organisation.count] }
  attendu = "Démarches #{nombres[0]} · #{nombres[1]} publiée"
  raise "catalogue #{lignes} != #{nombres}" unless lignes[0].start_with?(attendu) && lignes[1].start_with?("Solutions #{nombres[2]} · #{nombres[3]}") && lignes[2] == "Organisations #{nombres[4]}"

  Verify.evidence(DOSSIER, page, 'catalogue', "lignes=#{lignes.join(' | ')} en_base=#{nombres}")
end

def a_reprendre(page, demarche)
  premier = zone(page, 'À reprendre').first('li')
  textes = premier.all('p').map { it.text.squish }
  attendu = ["Démarche · brouillon du #{Date.current.strftime('%d/%m/%Y')}", demarche.nom, 'Contexte et adresse de la page modifiés']
  raise "à reprendre #{textes} != #{attendu}" unless textes == attendu

  Verify.evidence(DOSSIER, page, 'a-reprendre', "premier=#{textes.join(' | ')}")
  premier.click_link demarche.nom
  page.assert_current_path("/admin/demarches/#{demarche.id}/edit")
end

def dernieres_modifications(page, nom)
  page.visit('/admin')
  lignes = zone(page, 'Dernières modifications').all('tbody tr').first(2)
  cellules = lignes.map { |ligne| ligne.all('td').first(3).map(&:text) }
  liens = lignes.map { it.has_link?(nom, wait: 0) }
  raise "modifications #{cellules} liens=#{liens}" unless cellules == [['Vocabulaire', nom, 'Supprimé'], ['Démarche', nom, 'Modifiée']] && liens == [false, true]

  Verify.evidence(DOSSIER, page, 'dernieres-modifications', "lignes=#{cellules} liens=#{liens}")
end

def rafraichissement(page)
  boite = zone(page, 'Rafraîchissement depuis data.gouv')
  boite.assert_selector :button, 'Rafraîchir depuis data.gouv'
  boite.assert_no_text 'Grist'
  Verify.evidence(DOSSIER, page, 'rafraichissement', "encadre=#{boite.text.squish}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  demarche = Demarche.create!(nom:, slug:, visible: true)
  demarche.enregistrer('nom' => nom, 'contexte' => 'Contexte du brouillon', 'slug' => "#{slug}-v2", 'modifie_le' => Time.current)
  Vocabulaire.create!(nom:, slug:, categorie: 'usager').destroy!
  Verify.login(page)
  Verify.check('Catalogue') { catalogue(page) }
  Verify.check('À reprendre') { a_reprendre(page, demarche) }
  Verify.check('Dernières modifications') { dernieres_modifications(page, nom) }
  Verify.check('Rafraîchissement') { rafraichissement(page) }
  Verify.check('Proof') { Verify.logout(page) }
ensure
  Demarche.where(nom:).destroy_all
  Vocabulaire.where(nom:).destroy_all
end
