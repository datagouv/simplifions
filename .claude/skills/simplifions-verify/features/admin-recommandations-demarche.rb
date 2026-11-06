require_relative '../harness'

DOSSIER = 'admin-recommandations-demarche'.freeze

def compte(demarche) = ActiveRecord::Base.uncached { demarche.recommandations.count }

def blocs_de_la_demarche(page, demarche, avant)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  cartes = Verify.cartes_de_la_fiche(page).size
  donnees = page.all('.donnees-disponibles li').size
  raise "#{cartes} cartes et #{donnees} données utiles pour #{avant} recommandations" unless cartes + donnees == avant

  Verify.evidence(DOSSIER, page, 'demarche', "cartes=#{cartes} donnees=#{donnees} en_base=#{avant}")
end

def nouvelle(page, demarche)
  page.visit("/admin/recommandations/new?demarche_id=#{demarche.id}")
  choisie = page.find('#recommandation_demarche_id option[selected]').text
  raise "démarche pré-remplie #{choisie}" unless choisie == demarche.nom

  autres = page.find('table[aria-labelledby=autres-recommandations]', visible: :all).all('tbody tr', visible: :all).size
  Verify.evidence(DOSSIER, page, 'nouvelle', "demarche=#{choisie} autres=#{autres}")
end

def enregistrer(page, demarche, solution, avant)
  page.select solution.libelle_admin, from: 'Solution (obligatoire)'
  page.select 'Donnée utile (API ou jeu de données)', from: 'Type de recommandation'
  page.fill_in 'Position', with: '99'
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  creee = ActiveRecord::Base.uncached { demarche.recommandations.find_by!(solution:) }
  page.assert_current_path("/admin/recommandations/#{creee.id}/edit")
  raise "#{compte(demarche)} recommandations, attendu #{avant + 1}" unless compte(demarche) == avant + 1

  creee
end

def ouvrir_encart(page, demarche)
  encart = page.find('aside.fr-callout')
  encart.find('button', text: 'Autres recommandations de la démarche').click
  encart.assert_selector('table[aria-labelledby=autres-recommandations]', visible: true)
  Verify.evidence(DOSSIER, page, 'enregistree', "url=#{page.current_path} encart=#{encart.find('h2').text} autres=#{encart.all('tbody tr', visible: :all).size} en_base=#{compte(demarche)}")
  Verify.lien_nomme(encart, "Voir la fiche #{demarche.nom}").click
end

def retour_sur_la_demarche(page, demarche, solution, creee)
  page.assert_current_path("/admin/demarches/#{demarche.id}/edit")
  ligne = page.find('.donnees-disponibles li', text: solution.libelle_admin).text.squish
  raise "nouvelle donnée utile #{ligne.inspect}" unless ligne.end_with?('99')
  raise 'nouvelle recommandation absente de la fenêtre des données utiles' unless page.has_selector?("form#donnee_utile_recommandation_#{creee.id}", visible: :all)

  Verify.evidence(DOSSIER, page, 'retour-demarche', "donnee_utile=#{ligne}")
end

def supprimer(page, demarche, creee, avant)
  page.visit("/admin/recommandations/#{creee.id}/edit")
  page.accept_confirm { page.click_button 'Supprimer' }
  page.assert_current_path('/admin/recommandations')
  raise "#{compte(demarche)} recommandations, attendu #{avant}" unless compte(demarche) == avant

  Verify.evidence(DOSSIER, page, 'supprimee', "en_base=#{compte(demarche)} attendu=#{avant}")
end

def etroit(page, demarche)
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/recommandations/#{demarche.recommandations.first.id}/edit")
  Verify.evidence(DOSSIER, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  demarche = Demarche.visibles.max_by { |ligne| ligne.recommandations.count }
  solution = Solution.where(categorie: 'api').where.not(id: demarche.recommandations.select(:solution_id)).reject(&:privee?).first
  avant = demarche.recommandations.count
  Verify.login(page)
  Verify.check('Blocks') { blocs_de_la_demarche(page, demarche, avant) }
  creee = Verify.check('Add') do
    nouvelle(page, demarche)
    enregistrer(page, demarche, solution, avant)
  end
  Verify.check('Context') do
    ouvrir_encart(page, demarche)
    retour_sur_la_demarche(page, demarche, solution, creee)
  end
  Verify.check('Undo') { supprimer(page, demarche, creee, avant) }
  Verify.check('Proof') do
    etroit(page, demarche)
    Verify.logout(page)
  end
ensure
  Recommandation.where(demarche:, solution:).destroy_all if demarche && solution
end
