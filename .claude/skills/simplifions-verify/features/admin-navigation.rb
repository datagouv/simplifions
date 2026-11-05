require_relative '../harness'

DOSSIER = 'admin-navigation'.freeze
ENTREES_ADMIN = ['À reprendre', 'Démarches', 'Solutions', 'Référentiels'].freeze
REFERENTIELS = ['Organisations', 'Fournisseurs de services', 'Vocabulaires'].freeze
BARRE_PUBLIQUE = ['Accueil', "Cas d'usages", 'Articles', 'À propos'].freeze

def barre(page, nom)
  page.all("nav[aria-label='#{nom}'] .fr-nav__link", visible: :all).map { |lien| [lien.text(:all).strip, lien['aria-current']] }
end

def entrees(page)
  page.all("nav[aria-label='Menu de l’administration'] .fr-nav__list > .fr-nav__item > :is(.fr-nav__link, .fr-nav__btn)", visible: :all)
    .map { |entree| entree.text(:all).strip }
end

def rubrique_en_cours(page)
  page.all("nav[aria-label='Menu de l’administration'] [aria-current]", visible: :all).map { |entree| [entree.text(:all).strip, entree['aria-current']] }
end

def en_cours!(page, etape, attendu)
  en_cours = rubrique_en_cours(page)
  raise "#{etape} : en cours #{en_cours}" unless en_cours == attendu

  Verify.evidence(DOSSIER, page, etape, "chemin=#{page.current_path} en_cours=#{en_cours}")
end

def debord(page) = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')

def tableau_de_bord(page)
  Verify.login(page)
  page.visit('/admin')
  raise "entrées #{entrees(page)}" unless entrees(page) == ENTREES_ADMIN
  raise 'barre publique sous /admin' unless barre(page, 'Menu principal').empty?

  en_cours!(page, 'tableau-de-bord', [['À reprendre', 'page']])
end

def referentiels(page)
  page.click_button 'Référentiels'
  sous_menu = page.all('#menu-referentiels .fr-nav__link', count: REFERENTIELS.size).map(&:text)
  raise "sous-menu #{sous_menu}" unless sous_menu == REFERENTIELS

  Verify.evidence(DOSSIER, page, 'sous-menu-ouvert', "sous_menu=#{sous_menu}")
  page.click_link 'Organisations'
  page.assert_current_path('/admin/organisations')
  en_cours!(page, 'organisations', [%w[Référentiels true], %w[Organisations page]])
end

def hors_menu(page)
  page.visit('/admin/recommandations')
  page.assert_selector 'h1'
  en_cours!(page, 'recommandations-hors-menu', [])
end

def rubrique_solutions(page)
  Verify.rubrique(page, 'Solutions')
  page.assert_current_path('/admin/solutions')
  en_cours!(page, 'liste-solutions', [%w[Solutions page]])
  solution = Solution.first
  page.visit("/admin/solutions/#{solution.id}/edit")
  en_cours!(page, 'fiche-solution', [%w[Solutions true]])
  page.visit("/admin/historique/solutions/#{solution.id}")
  en_cours!(page, 'historique', [%w[Solutions true]])
end

def menu_mobile(page)
  page.current_window.resize_to(375, 800)
  page.visit('/admin')
  page.click_button 'Menu'
  page.within('#modal-menu') do
    raise "mobile #{entrees(page)}" unless entrees(page) == ENTREES_ADMIN

    page.click_button 'Référentiels'
    Verify.evidence(DOSSIER, page, 'menu-375', "entrees=#{entrees(page).size}")
    page.click_link 'Vocabulaires'
  end
end

def vocabulaires_mobile(page)
  page.assert_current_path('/admin/vocabulaires')
  raise "375 px : débord #{debord(page)}" if debord(page).positive?

  en_cours!(page, 'vocabulaires-375', [%w[Référentiels true], %w[Vocabulaires page]])
  page.current_window.resize_to(1280, 1024)
end

def site_public(page)
  page.visit('/')
  publique = barre(page, 'Menu principal').map(&:first)
  raise "public #{publique}" unless publique == BARRE_PUBLIQUE
  raise 'barre admin sur le site public' unless barre(page, 'Menu de l’administration').empty?

  Verify.evidence(DOSSIER, page, 'site-public', "barre=#{publique}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Tableau de bord') { tableau_de_bord(page) }
  Verify.check('Rubrique') { rubrique_solutions(page) }
  Verify.check('Référentiels') { referentiels(page) }
  Verify.check('Hors menu') { hors_menu(page) }
  Verify.check('Mobile') { menu_mobile(page).then { vocabulaires_mobile(page) } }
  Verify.check('Site public') { site_public(page) }
  Verify.check('Proof') { raise 'aucune capture' if Dir[Verify::ROOT.join(DOSSIER, "#{Verify.browser}-*.png")].empty? }
ensure
  page.current_window.resize_to(1280, 1024)
end
