require_relative '../harness'

DOSSIER = 'pied-de-page'.freeze
CATEGORIES = ['Démarches référencées à destination des :', 'Démarches référencées gérées par les :',
              '3 guides pour débuter :', 'Découvrir les solutions raccordées aux données :',
              'Comparer le nombre de données raccordées par solution :',
              'Simplifions.data.gouv.fr', 'Aide', 'Contribution'].freeze

def categories_lues(page, etape)
  pied = page.find('footer')
  pied.assert_selector 'h3', text: CATEGORIES.last
  categories = pied.all('h3').map(&:text)
  raise "#{etape} : catégories #{categories}" unless categories == CATEGORIES

  page.scroll_to(pied)
  Verify.evidence(DOSSIER, page, etape, "url=#{page.current_path} categories=#{categories.size}")
end

def categories_aux_deux_largeurs(page)
  [[1280, 'accueil-1280'], [375, 'accueil-375']].each do |largeur, etape|
    page.current_window.resize_to(largeur, 1024)
    page.visit('/')
    categories_lues(page, etape)
  end
  page.current_window.resize_to(1280, 1024)
end

def liens_des_cinq_blocs(page)
  page.visit('/')
  page.find('footer').all('h3').first(5).flat_map do |categorie|
    categorie.all(:xpath, 'following-sibling::ul[1]//a').map do |lien|
      adresse = URI(lien[:href])
      [lien.text, [adresse.request_uri, adresse.fragment].compact.join('#')]
    end
  end
end

def en_quoi_aider(page)
  page.visit('/demarches')
  page.find('footer').click_link('En quoi simplifions.data.gouv.fr peut-il vous aider ?')
  page.assert_current_path('/')
  haut = "Math.round(document.getElementById('comment-vous-aider').getBoundingClientRect().top)"
  page.document.synchronize do
    arrivee = [page.evaluate_script('location.hash'), page.evaluate_script(haut)]
    raise Capybara::ExpectationNotMet, "section aider : #{arrivee}" unless arrivee == ['#comment-vous-aider', 0]
  end
  Verify.evidence(DOSSIER, page, 'en-quoi-aider', 'depuis=/demarches hash=#comment-vous-aider haut_section=0')
end

def compte(page, attendu, libelle)
  affiche = page.find('[role=status]').text[/\d+/].to_i
  raise "#{libelle} : #{affiche} affichés, base #{attendu}" unless affiche == attendu && attendu.positive?
end

def verifier_la_destination(page, adresse, libelle)
  params = Rack::Utils.parse_query(adresse.query)
  case adresse.path
  when '/demarches' then compte(page, Demarche.catalogue(params).count, libelle)
  when '/solutions' then compte(page, Solution.catalogue(params).count, libelle)
  when %r{\A/solutions/} then page.assert_selector('#solutions-integratices .solution-integratrice-card', minimum: 1)
  else page.assert_selector('h1')
  end
end

def destination(page, libelle, chemin)
  page.visit('/')
  page.find('footer').find_link(href: chemin).click
  adresse = URI(chemin)
  page.assert_current_path(adresse.path + (adresse.query ? "?#{adresse.query}" : ''))
  verifier_la_destination(page, adresse, libelle)
end

def liens_suivis(page)
  liens = liens_des_cinq_blocs(page)
  liens.each { |libelle, chemin| destination(page, libelle, chemin) }
  Verify.evidence(DOSSIER, page, 'liens-suivis', "#{liens.size} liens : #{liens.map(&:last).join(' ')}")
end

def dans_l_admin(page)
  Verify.login(page)
  page.visit('/admin')
  categories_lues(page, 'admin')
  Verify.logout(page)
end

Verify.drive(__FILE__) do |page|
  Verify.check('Categories') { categories_aux_deux_largeurs(page) }
  Verify.check('Presentation link') { en_quoi_aider(page) }
  Verify.check('Links') { liens_suivis(page) }
  Verify.check('Admin') { dans_l_admin(page) }
  Verify.check('Proof') { Verify.captures_presentes(DOSSIER, %w[accueil-1280 accueil-375 en-quoi-aider liens-suivis admin]) }
end
