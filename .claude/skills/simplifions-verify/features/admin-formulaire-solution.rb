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

def privee_dans_la_liste(page, solution)
  page.visit('/admin/solutions')
  Verify.rechercher(page, solution.nom)
  privee = page.find('tbody tr', text: solution.nom).all('td')[2][:textContent].strip
  raise "colonne Privée #{privee.inspect}" unless privee == 'Oui'

  Verify.evidence(DOSSIER, page, 'liste', "colonne_privee=#{privee} en_base=#{solution.privee?}")
end

def badge_privee(page, solution)
  page.click_link solution.libelle_admin
  badge = page.find('h1 + .fr-badge')[:textContent].strip
  raise "badge=#{badge}" unless badge == 'Privée'
end

def image(page, solution)
  alt = page.find('.fr-upload-group img')['alt']
  aide = page.find('label[for=solution_image] .fr-hint-text').text
  raise "alt=#{alt} aide=#{aide}" unless alt == solution.legende_image && aide.include?('png, jpg, webp')

  Verify.evidence(DOSSIER, page, 'fiche', "alt=#{alt} aide=#{aide} description_masquee,desactivee=#{champ_masque(page, 'solution_description_courte')}")
end

def api_choisie(page)
  page.select 'API', from: 'Catégorie de solution'
  etat = etat_des_champs(page, %w[solution_slug solution_description_courte solution_legende_image solution_retirer_image])
  attendu = { 'solution_slug' => [true, true], 'solution_description_courte' => [true, true],
              'solution_legende_image' => [false, false], 'solution_retirer_image' => [false, false] }
  raise "API : #{etat}" unless etat == attendu

  Verify.demande_avant_de_partir(page, 'Quitter sans enregistrer les modifications ?') { page.click_link 'Annuler' }
  Verify.evidence(DOSSIER, page, 'api-choisie', "masque,desactive=#{etat} confirmation=demandee")
end

def brique_rechoisie(page)
  page.select 'Brique technique', from: 'Catégorie de solution'
  masque = champ_masque(page, 'solution_description_courte')
  raise "brique : description #{masque}" unless masque == [false, false]

  Verify.evidence(DOSSIER, page, 'brique-rechoisie', "description_masquee,desactivee=#{masque}")
end

def vider_puis_api(page)
  page.fill_in 'Légende de l’image', with: ''
  page.check 'Retirer l’image', allow_label_click: true
  page.select 'API', from: 'Catégorie de solution'
  etat = etat_des_champs(page, %w[solution_legende_image solution_retirer_image])
  raise "vidés puis API : #{etat}" unless etat.values.all?([false, false])

  Verify.evidence(DOSSIER, page, 'vides-puis-api', "masque,desactive=#{etat}")
end

def api_sans_legende_ni_image?(solution) = solution.categorie == 'api' && solution.legende_image.blank? && !solution.image.attached?

def enregistrer(page, solution)
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  en_base = ActiveRecord::Base.uncached { Solution.find(solution.id) }
  lu = "categorie=#{en_base.categorie} legende=#{en_base.legende_image.inspect} image=#{en_base.image.attached?}"
  raise "base #{lu}" unless api_sans_legende_ni_image?(en_base)

  Verify.evidence(DOSSIER, page, 'api-enregistree', "#{lu} legende_masquee,desactivee=#{champ_masque(page, 'solution_legende_image')} badge=#{page.has_css?('h1 + .fr-badge', wait: 0)}")
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
  Verify.check('Privée') do
    privee_dans_la_liste(page, solution)
    badge_privee(page, solution)
  end
  Verify.check('Image') { image(page, solution) }
  Verify.check('Catégorie') do
    api_choisie(page)
    brique_rechoisie(page)
  end
  Verify.check('One save') do
    vider_puis_api(page)
    enregistrer(page, solution)
  end
  Verify.check('Proof') do
    etroit(page, solution)
    Verify.logout(page)
  end
ensure
  Solution.where(nom:).destroy_all
end
