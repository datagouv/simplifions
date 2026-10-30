require_relative '../harness'

DOSSIER = 'admin-previsualisation'.freeze
IMAGE = Rails.root.join('app/assets/images/articles/api-franceconnectees-donnees-personnelles.png').to_s

def previsualiser(page)
  fenetre = page.window_opened_by { page.click_link 'Prévisualiser' }
  page.switch_to_window(fenetre)
  yield fenetre
ensure
  fenetre&.close
  page.switch_to_window(page.windows.first)
end

def previsualisation_lisible(page)
  page.current_window.resize_to(640, 1024)
  largeurs = page.evaluate_script('[document.documentElement.scrollWidth, document.documentElement.clientWidth]')
  page.current_window.resize_to(1280, 1024)
  raise "débord à 640 px #{largeurs}" if largeurs.first > largeurs.last

  largeurs
end

def brouillon_de_demarche(page, nom)
  Verify.ouvrir_fiche(page, nom)
  page.assert_no_selector :link, 'Prévisualiser'
  page.fill_in 'Nom', with: "#{nom} brouillon"
  page.click_button 'Enregistrer'
end

def demarche_previsualisee(page, nom)
  page.assert_selector 'h1', text: "#{nom} brouillon"
  page.assert_selector '.fr-notice', text: 'Prévisualisation, non publiée.'
  Verify.evidence(DOSSIER, page, 'demarche', "h1=#{page.find('h1').text} titre=#{page.title} bandeau=#{page.find('.fr-notice').text.squish}")
  Verify.evidence(DOSSIER, page, 'demarche-640px', "scrollWidth/clientWidth=#{previsualisation_lisible(page)}")
end

def page_publique_inchangee(page, demarche)
  titre = Verify.titre_public(page, demarche.slug)
  base = ActiveRecord::Base.uncached { demarche.reload.nom }
  raise "page publique #{titre} / base #{base}" unless [titre, base].all?(demarche.nom)

  Verify.evidence(DOSSIER, page, 'page-publique-inchangee', "h1=#{titre} base=#{base} bandeau=#{page.has_css?('.fr-notice', wait: 0)}")
end

def image_en_brouillon(page, solution)
  Verify.rubrique(page, 'Solutions')
  Verify.ouvrir_depuis_la_liste(page, solution.nom)
  page.attach_file('solution_image', IMAGE)
  page.click_button 'Enregistrer'
end

def image_previsualisee(page, solution)
  page.assert_selector '.fr-content-media img[src*="api-franceconnectees-donnees-personnelles.png"]'
  attachee = ActiveRecord::Base.uncached { Solution.find(solution.id).image.attached? }
  raise 'image attachée par la prévisualisation' if attachee

  Verify.evidence(DOSSIER, page, 'solution-image', "image_du_brouillon=affichee image_en_base=#{attachee}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Verify.login(page)
  demarche = Demarche.create!(nom:, slug:, visible: true)

  Verify.check('Démarche') do
    brouillon_de_demarche(page, nom)
    previsualiser(page) { demarche_previsualisee(page, nom) }
  end
  Verify.check('Public page unchanged') { page_publique_inchangee(page, demarche) }
  Verify.check('Solution image') do
    solution = Solution.create!(nom:, slug:, visible: true)
    image_en_brouillon(page, solution)
    previsualiser(page) { image_previsualisee(page, solution) }
  end
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).destroy_all
end
