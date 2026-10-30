require_relative '../harness'

DOSSIER = 'admin-identifiant-datagouv'.freeze
MELODI = '6661e09c7230a8fc3b1ec229'.freeze
SIRENE = '672cf6aece89cb14e31f0fba'.freeze

def nouvelle_api(page, nom, uid)
  page.visit('/admin/solutions/new')
  page.fill_in 'Nom', with: nom
  page.select 'API', from: 'Catégorie de solution'
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
  page.assert_text "« #{nom} (API) » enregistré."
  api = ActiveRecord::Base.uncached { Solution.find_by!(nom:) }
  raise 'rien repris de data.gouv.fr' if api.datagouv_titre.blank?

  bloc_repris(page, api)
  Verify.evidence(DOSSIER, page, 'creation', "uid=#{api.uid_datagouv} titre=#{api.datagouv_titre} organisation=#{api.datagouv_organisation}")
  api
end

def saisir_inconnu(page, nom)
  page.fill_in 'Identifiant data.gouv', with: 'verif-identifiant-inconnu'
  page.click_button 'Enregistrer'
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

def quitter(page)
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  api = Verify.check('Creation') { creer(page, nom) }
  Verify.check('Inconnu') { identifiant_inconnu(page, api, nom) }
  Verify.check('Doublon') { doublon(page, nom) }
  Verify.check('Proof') { quitter(page) }
ensure
  ActiveRecord::Base.uncached { Solution.where('nom LIKE ?', "#{nom}%").destroy_all }
end
