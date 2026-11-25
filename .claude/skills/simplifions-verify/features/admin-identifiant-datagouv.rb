require_relative '../harness'

DOSSIER = 'admin-identifiant-datagouv'.freeze
MELODI = '6661e09c7230a8fc3b1ec229'.freeze
SIRENE = '672cf6aece89cb14e31f0fba'.freeze

def nouvelle_fiche_d_api(page)
  page.visit('/admin/solutions/new')
  page.find('label[for=choix-categorie-api]').click
  page.click_button 'Continuer'
  page.assert_text 'Catégorie de solution : API'
end

def nouvelle_api(page, nom, uid)
  nouvelle_fiche_d_api(page)
  page.fill_in 'Nom', with: nom
  page.check 'API', allow_label_click: true
  page.fill_in 'Identifiant data.gouv', with: uid
  page.click_button 'Enregistrer'
end

def bloc_datagouv(page) = page.find('h2', text: 'Repris de data.gouv.fr').find(:xpath, '..')

def bloc_repris(page, api)
  bloc_datagouv(page).assert_text "Titre : #{api.datagouv_titre}"
  page.assert_no_text 'Rien n’a été repris'
  page.scroll_to(bloc_datagouv(page), align: :center)
end

def creer(page, nom)
  raise "#{MELODI} déjà en base" if Solution.exists?(uid_datagouv: MELODI)

  nouvelle_api(page, nom, MELODI)
  page.assert_text "« #{nom} (API) » enregistré.", wait: 40
  api = ActiveRecord::Base.uncached { Solution.find_by!(nom:) }
  raise 'rien repris de data.gouv.fr' if api.datagouv_titre.blank?

  bloc_repris(page, api)
  Verify.evidence(DOSSIER, page, 'creation', "uid=#{api.uid_datagouv} titre=#{api.datagouv_titre} organisation=#{api.datagouv_organisation}")
  api
end

def saisir_inconnu(page, nom)
  page.fill_in 'Identifiant data.gouv', with: 'verif-identifiant-inconnu'
  page.execute_script('document.body.dataset.pageAvantEnregistrement = ""')
  page.click_button 'Enregistrer'
  page.assert_no_selector('body[data-page-avant-enregistrement]', wait: 40)
  page.assert_text "« #{nom} (API) » enregistré."
end

def identifiant_inconnu(page, api, nom)
  saisir_inconnu(page, nom)
  bloc_datagouv(page).assert_text 'Rien n’a été repris de data.gouv.fr pour cet identifiant'
  ActiveRecord::Base.uncached { api.reload }
  raise "datagouv_titre #{api.datagouv_titre.inspect}" unless api.datagouv_titre.nil?

  page.scroll_to(bloc_datagouv(page), align: :center)
  Verify.evidence(DOSSIER, page, 'inconnu', "uid=#{api.uid_datagouv} titre=#{api.datagouv_titre.inspect}")
end

def doublon(page, nom)
  sirene = Solution.find_by!(uid_datagouv: SIRENE)
  nouvelle_api(page, "#{nom} doublon", SIRENE)
  page.assert_text "est déjà celui de « #{sirene.libelle_admin} »"
  doublons = ActiveRecord::Base.uncached { Solution.where(uid_datagouv: SIRENE).count }
  raise "#{doublons} fiches avec #{SIRENE}" unless doublons == 1

  page.scroll_to(page.find_field('Identifiant data.gouv'), align: :center)
  Verify.evidence(DOSSIER, page, 'doublon', "refusé, fiches avec #{SIRENE} : #{doublons} (#{sirene.libelle_admin})")
end

def saisir_identifiant(page, uid, touche: nil)
  page.fill_in 'Identifiant data.gouv', with: uid
  touche ? page.find_field('Identifiant data.gouv').send_keys(touche) : page.click_button('Récupérer les infos data.gouv')
end

def titre_apercu(page, ancien = nil)
  page.assert_no_selector('#repris-datagouv li', exact_text: "Titre : #{ancien}", wait: 40) if ancien
  page.assert_selector('#repris-datagouv li', text: /\ATitre : \S/, wait: 40)
  page.find('#repris-datagouv li', text: 'Titre :').text.delete_prefix('Titre : ')
end

ATTENTE = 'Recherche de cet identifiant sur data.gouv.fr…'.freeze

def noter_les_annonces(page)
  page.execute_script(<<~JS)
    window.annonces = []
    new MutationObserver(() => document.querySelectorAll('[role=status]').forEach(({ textContent }) => {
      if (textContent.trim()) window.annonces.push(textContent.trim())
    })).observe(document.body, { childList: true, characterData: true, subtree: true })
  JS
end

def attente_annoncee(page)
  annonces = page.evaluate_script('window.annonces')
  raise "annonces pendant l’aperçu : #{annonces.inspect}" unless annonces.include?(ATTENTE)

  page.assert_no_selector('[role=status]', text: ATTENTE)
end

def nom_tape_garde(page, nom, melodi)
  page.fill_in 'Nom', with: "#{nom} tapé"
  saisir_identifiant(page, MELODI, touche: :enter)
  page.assert_selector('#repris-datagouv li', exact_text: "Titre : #{melodi}", wait: 40)
  page.assert_selector(:field, 'Nom', with: "#{nom} tapé")
end

def rien_enregistre(page, melodi)
  raise "#{MELODI} enregistré par l’aperçu" if ActiveRecord::Base.uncached { Solution.exists?(uid_datagouv: MELODI) }

  page.scroll_to(bloc_datagouv(page), align: :center)
  Verify.evidence(DOSSIER, page, 'apercu', "titre=#{melodi} nom gardé=#{page.find_field('Nom').value} rien enregistré")
end

def organisation_cochee(page)
  organisation = Solution.find_by!(uid_datagouv: SIRENE).organisation_de_datagouv || raise('aucune organisation de la liste pour Sirene')
  bloc_datagouv(page).assert_text "correspond à « #{organisation.nom} » de la liste Organisations"
  page.assert_selector(:checkbox, organisation.nom, exact_text: true, checked: true, visible: :all)
  page.assert_selector('[role=status]', text: 'Nom et organisation repris de data.gouv.fr : enregistrez la fiche pour les garder.')
  page.scroll_to(bloc_datagouv(page), align: :center)
  Verify.evidence(DOSSIER, page, 'organisation', "organisation data.gouv=#{organisation.nom} cochée")
end

def apercu(page, nom)
  nouvelle_fiche_d_api(page)
  noter_les_annonces(page)
  saisir_identifiant(page, MELODI)
  melodi = titre_apercu(page)
  attente_annoncee(page)
  page.assert_selector(:field, 'Nom', with: melodi)
  bloc_datagouv(page).assert_text '(absente de la liste Organisations)'
  saisir_identifiant(page, SIRENE)
  page.assert_selector(:field, 'Nom', with: titre_apercu(page, melodi))
  organisation_cochee(page)
  nom_tape_garde(page, nom, melodi)
  rien_enregistre(page, melodi)
  revenir_a_la_liste(page)
end

def revenir_a_la_liste(page)
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.within('nav[aria-label="vous êtes ici :"]') { page.click_link 'Solutions' } }
  page.assert_text 'Choisissez une solution dans la liste'
end

def hauteur_du_bloc(page) = page.evaluate_script('document.getElementById("repris-datagouv").offsetHeight')

def api_avec_organisation
  Solution.sur_datagouv.where.not(datagouv_titre: nil).joins(:organisations).first || raise('aucune API reprise de data.gouv avec une organisation')
end

def bloc_garde_au_survol(page, api)
  avant = hauteur_du_bloc(page)
  page.first(:link, 'Voir la fiche').hover
  sleep 1
  bloc_datagouv(page).assert_text "Titre : #{api.datagouv_titre}"
  raise "bloc data.gouv de #{avant} px à #{hauteur_du_bloc(page)} px au survol" unless hauteur_du_bloc(page) == avant

  avant
end

def survol_sans_saut(page)
  api = api_avec_organisation
  page.visit("/admin/solutions/#{api.id}/edit")
  bloc_datagouv(page).assert_text "Titre : #{api.datagouv_titre}"
  hauteur = bloc_garde_au_survol(page, api)
  Verify.evidence(DOSSIER, page, 'survol', "fiche=#{api.libelle_admin} bloc=#{hauteur} px avant et après le survol de « Voir la fiche »")
end

def quitter(page)
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  Verify.check('Aperçu') { apercu(page, nom) }
  api = Verify.check('Creation') { creer(page, nom) }
  Verify.check('Inconnu') { identifiant_inconnu(page, api, nom) }
  Verify.check('Survol') { survol_sans_saut(page) }
  Verify.check('Doublon') { doublon(page, nom) }
  Verify.check('Proof') { quitter(page) }
ensure
  ActiveRecord::Base.uncached { Solution.where('nom LIKE ?', "#{nom}%").destroy_all }
end
