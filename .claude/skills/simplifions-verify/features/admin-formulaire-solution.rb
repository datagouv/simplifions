require_relative '../harness'

DOSSIER = 'admin-formulaire-solution'.freeze
IMAGE = 'app/assets/images/articles/api-franceconnectees-donnees-personnelles.png'.freeze

def champ_masque(page, id)
  page.evaluate_script("(c => [!!c.closest('.fr-hidden'), c.disabled])(document.getElementById('#{id}'))")
end

def etat_des_champs(page, ids) = ids.index_with { |id| champ_masque(page, id) }

def creer_solution(nom)
  solution = Solution.new(nom:, categorie: 'brique_logicielle', legende_image: 'Écran de vérification')
  solution.image.attach(io: Rails.root.join(IMAGE).open, filename: 'verif.png')
  solution.tap(&:save!)
end

def badge_privee(page, solution)
  page.visit('/admin/solutions')
  Verify.ouvrir_depuis_la_liste(page, solution.nom)
  badge = page.find('h1 + .fr-badge')[:textContent].strip
  raise "badge=#{badge}" unless badge == 'Privée' && solution.privee?

  Verify.evidence(DOSSIER, page, 'badge-privee', "badge=#{badge} en_base=#{solution.privee?}")
end

def image(page, solution)
  alt = page.find('.fr-upload-group img')['alt']
  aide = page.find('label[for=solution_image] .fr-hint-text').text
  raise "alt=#{alt} aide=#{aide}" unless alt == solution.legende_image && aide.include?('png, jpg, webp')

  Verify.evidence(DOSSIER, page, 'fiche', "alt=#{alt} aide=#{aide} description_masquee,desactivee=#{champ_masque(page, 'solution_description_courte')}")
end

def choisir(page, nom, categorie) = page.find("label[for=choix-#{nom}-#{categorie}]").click

def categorie_affichee(page) = page.find('#formulaire-fiche p', text: 'Catégorie de solution :').text.squish

def aide_du_choix(page, categorie)
  page.find("label[for=choix-nouvelle-categorie-#{categorie}] .fr-hint-text", visible: :all)[:textContent].squish
end

def ouvrir_la_fenetre(page)
  page.click_button 'Changer de catégorie'
  page.find('dialog[open]', text: 'Nouvelle catégorie')
end

def continuer_sans_choix(page)
  page.visit('/admin/solutions/new')
  raise 'formulaire affiché avant la catégorie' if page.has_field?('Nom', wait: 0)

  page.click_button 'Continuer'
  page.assert_text 'Choisissez une catégorie.'
end

def continuer_avec(page, categorie)
  choisir(page, 'categorie', categorie)
  page.click_button 'Continuer'
  [categorie_affichee(page), champ_masque(page, 'solution_description_courte')]
end

def changer_sans_rien_saisir(page)
  ouvrir_la_fenetre(page)
  choisir(page, 'nouvelle-categorie', 'logiciel_metier_cle_en_main')
  page.click_button 'Changer et enregistrer'
  page.assert_text 'Nom doit être rempli'
  categorie_affichee(page)
end

def premiere_etape(page)
  avant = Solution.count
  continuer_sans_choix(page)
  api, masque = continuer_avec(page, 'api')
  logiciel = changer_sans_rien_saisir(page)
  cree = ActiveRecord::Base.uncached { Solution.count } - avant
  lu = "#{api} description_masquee,desactivee=#{masque} puis #{logiciel} creees=#{cree}"
  raise lu unless api.end_with?(': API') && masque == [true, true] && logiciel.end_with?(': Logiciel métier') && cree.zero?

  Verify.evidence(DOSSIER, page, 'premiere-etape', lu)
end

def filtres(page) = Rack::Utils.parse_query(URI(page.current_url).query).slice('q', 'etat')

def filtres_de_la_liste(page) = { 'q' => page.find_field('Rechercher une solution').value, 'etat' => page.find_field('État').value }

def ajouter_depuis_la_liste_filtree(page, nom)
  attendus = { 'q' => 'verify-map', 'etat' => 'masquees' }
  page.visit('/admin/solutions?q=verify-map&etat=masquees')
  page.within('nav[aria-label="Liste des solutions"]') { page.click_link 'Ajouter une solution' }
  choisir(page, 'categorie', 'brique_logicielle')
  page.click_button 'Continuer'
  page.find_field('Nom')
  apres_continuer = [filtres(page), filtres_de_la_liste(page)]
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer', match: :first
  page.assert_text 'enregistré'
  lu = "apres_continuer=#{apres_continuer} apres_enregistrer=#{filtres(page)} creee=#{ActiveRecord::Base.uncached { Solution.exists?(nom:) }}"
  raise lu unless apres_continuer == [attendus, attendus] && filtres(page) == attendus && Solution.exists?(nom:)

  Verify.evidence(DOSSIER, page, 'filtres-gardes', lu)
end

def fenetre(page)
  ouvrir_la_fenetre(page)
  aides = { 'api' => aide_du_choix(page, 'api'), 'logiciel' => aide_du_choix(page, 'logiciel_metier_cle_en_main') }
  raise "aides=#{aides}" unless aides['api'].start_with?('Efface : Slug') && aides['logiciel'] == 'Rien n’est effacé.'

  Verify.evidence(DOSSIER, page, 'fenetre', "aides=#{aides}")
  page.within('dialog[open]') { page.click_button 'Annuler' }
  page.assert_no_selector('dialog[open]')
end

def publiee(page, solution)
  solution.update!(visible: true)
  page.visit("/admin/solutions/#{solution.id}/edit")
  ouvrir_la_fenetre(page)
  refusees = %w[api base_de_donnees].index_with { page.find("#choix-nouvelle-categorie-#{it}", visible: :all).disabled? }
  aide = aide_du_choix(page, 'api')
  raise "refusees=#{refusees} aide=#{aide}" unless refusees.values.all? && aide.start_with?('Masquez d’abord')

  Verify.evidence(DOSSIER, page, 'publiee', "refusees=#{refusees} aide=#{aide}")
ensure
  solution.update!(visible: false)
end

def api_sans_legende_ni_image?(solution) = solution.categorie == 'api' && solution.legende_image.blank? && !solution.image.attached?

def relire(page, en_base)
  "categorie=#{en_base.categorie} nom=#{en_base.nom} legende=#{en_base.legende_image.inspect} image=#{en_base.image.attached?} page=#{categorie_affichee(page)}"
end

def changer_et_enregistrer(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  ouvrir_la_fenetre(page)
  choisir(page, 'nouvelle-categorie', 'api')
  page.click_button 'Changer et enregistrer'
  page.assert_text 'enregistré'
  en_base = ActiveRecord::Base.uncached { Solution.find(solution.id) }
  lu = relire(page, en_base)
  raise "base #{lu}" unless api_sans_legende_ni_image?(en_base) && en_base.nom == solution.nom && lu.end_with?(': API')

  Verify.evidence(DOSSIER, page, 'api-enregistree', lu)
end

def etroit(page, solution)
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/solutions/#{solution.id}/edit")
  Verify.evidence(DOSSIER, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  solution = creer_solution(nom)
  Verify.login(page)
  Verify.check('Privée') { badge_privee(page, solution) }
  Verify.check('Image') { image(page, solution) }
  Verify.check('Première étape') { premiere_etape(page) }
  Verify.check('Filtres gardés') { ajouter_depuis_la_liste_filtree(page, "#{nom} ajoutée") }
  Verify.check('Catégorie') do
    page.visit("/admin/solutions/#{solution.id}/edit")
    fenetre(page)
  end
  Verify.check('Publiée') { publiee(page, solution) }
  Verify.check('One save') { changer_et_enregistrer(page, solution) }
  Verify.check('Proof') do
    etroit(page, solution)
    Verify.logout(page)
  end
ensure
  Solution.where(nom: [nom, "#{nom} ajoutée"]).destroy_all
end
