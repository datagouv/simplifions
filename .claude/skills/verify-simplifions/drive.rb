require_relative 'harness'

page = Verify.session
only = ARGV.first

def catalogue(page)
  page.visit('/demarches')
  total = page.find('[role=status]').text[/\d+/].to_i
  raise 'catalogue vide' unless total.positive?

  page.fill_in 'Recherche', with: 'marchés publics'
  page.click_button 'Recherche'
  page.assert_current_path(/q=march/, url: false)
  filtres = page.find('[role=status]').text[/\d+/].to_i
  page.select 'Entreprises', from: 'Démarches à destination des :'
  page.assert_current_path(/target-users=entreprises/, url: false)
  filtres2 = page.find('[role=status]').text[/\d+/].to_i
  attendu = Demarche.catalogue({ 'q' => 'marchés publics', 'target-users' => 'entreprises' }).count
  raise "compte #{filtres2} != base #{attendu}" unless filtres2 == attendu

  Verify.evidence('catalogue-cas-usages', page, 'filtre',
    "total=#{total} recherche=#{filtres} recherche+entreprises=#{filtres2} base=#{attendu}")
end

def fiche(page)
  page.visit('/demarches')
  titre = page.first('h3 a').text
  page.click_link titre
  page.assert_selector 'h1', text: titre
  page.assert_selector 'h2', text: 'Données disponibles'
  section = page.find('section', text: 'Données disponibles', match: :first)
  section.first("button[aria-expanded='false']").click
  section.assert_selector "button[aria-expanded='true']"
  demarche = Demarche.visibles.find_by!(nom: Demarche.visibles.find { |d| d.titre == titre }.nom)
  Verify.evidence('fiche-cas-usage', page, 'accordeon-ouvert',
    "slug=#{demarche.slug} recommandations_niveau_2=#{demarche.recommandations.visibles.niveau_2.count} " \
    "accordeons_ouverts=#{section.all('button[aria-expanded=true]').size}")
end

def connexion(page)
  page.visit('/admin')
  page.assert_text 'Vous devez vous connecter pour accéder à cette page.'
  Verify.login(page)
  page.assert_selector 'h1', text: 'Administration'
  page.assert_selector :link, 'Administration'
  Verify.evidence('connexion-admin', page, 'tableau-de-bord', "path=#{page.current_path}")
  page.click_button 'Se déconnecter'
  page.assert_selector :link, 'Se connecter'
  page.visit('/admin')
  page.assert_current_path('/admin/connexion')
  Verify.evidence('connexion-admin', page, 'deconnecte', "path apres deconnexion=#{page.current_path}")
end

def vocabulaires(page)
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  page.click_link 'Vocabulaires'
  page.assert_selector 'h1', text: 'Vocabulaires'
  page.click_link 'Ajouter'
  page.fill_in 'Nom', with: nom
  page.fill_in 'Slug', with: "verif-verify-map-#{Verify.browser}"
  page.select 'Usager', from: 'Catégorie'
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  ligne = Vocabulaire.find_by!(nom:)
  page.assert_current_path("/admin/vocabulaires/#{ligne.id}/edit")
  page.assert_selector 'h1', text: nom
  fil = page.all('.fr-breadcrumb__list li', visible: :all).map { |etape| etape.text(:all).strip }
  raise "fil #{fil}" unless fil == ['Administration', 'Vocabulaires', nom]

  Verify.evidence('admin-vocabulaires', page, 'cree',
    "id=#{ligne.id} nom=#{ligne.nom} categorie=#{ligne.categorie} url=#{page.current_path} fil=#{fil.join(' > ')} onglet=#{page.title}")
  page.fill_in 'Nom', with: "#{nom} modifié"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} modifié » enregistré."
  page.assert_selector 'h1', text: "#{nom} modifié"
  Verify.evidence('admin-vocabulaires', page, 'modifie',
    "url=#{page.current_path} nom_en_base=#{ActiveRecord::Base.uncached { ligne.reload.nom }} onglet=#{page.title}")
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  page.click_link 'Vocabulaires'
  page.assert_no_selector :button, 'Supprimer'
  ouvrir_depuis_la_liste(page, nom)
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  page.assert_no_selector 'td', text: nom
  Verify.evidence('admin-vocabulaires', page, 'supprime', "reste_en_base=#{Vocabulaire.where(nom:).count}")
  Verify.logout(page)
end

def cascade(page)
  nom = "Vérif verify-map #{Verify.browser}"
  solution = Solution.order(:id).find { |s| !s.privee? }
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution:)
  Verify.login(page)
  page.click_link 'Démarches'
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence('admin-supprimer-demarche', page, 'avant',
    "demarche=#{demarche.id} recommandations=#{Recommandation.where(demarche:).count} solution=#{solution.id}")
  ouvrir_depuis_la_liste(page, nom)
  page.accept_confirm("Supprimer « #{nom} » ? 1 recommandation sera supprimée.") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  page.assert_no_selector 'td', text: nom
  ActiveRecord::Base.uncached do
    Verify.evidence('admin-supprimer-demarche', page, 'apres',
      "demarche_en_base=#{Demarche.where(nom:).count} recommandations=#{Recommandation.where(demarche:).count} " \
      "solution_en_base=#{Solution.where(id: solution.id).count}")
  end
  organisation = Organisation.order(:id).find { |o| o.solutions_rendues_privees.exists? }
  privees = organisation.solutions_rendues_privees.order(:nom).pluck(:nom)
  page.visit("/admin/organisations/#{organisation.id}/edit")
  message = page.dismiss_confirm { page.click_button 'Supprimer' }
  raise "confirmation #{message}" unless message.include?(privees.join(', '))

  Verify.evidence('admin-supprimer-demarche', page, 'organisation-annulee',
    "organisation=#{organisation.id} privees=#{privees.size} en_base=#{Organisation.where(id: organisation.id).count} confirmation=#{message}")
  Verify.logout(page)
end

def saisies(page)
  Verify.login(page)
  solution = Solution.visibles.fiches.where.not(slug: nil).order(:id).find { |s| !s.privee? }
  site_avant = solution.site_internet
  page.visit("/admin/solutions/#{solution.id}/edit")
  page.fill_in 'Site internet', with: 'www.exemple-verif.fr'
  page.click_button 'Enregistrer'
  page.assert_text "« #{solution.nom} » enregistré."
  page.visit("/solutions/#{solution.slug}")
  page.assert_selector :link, 'Site de la solution', href: 'https://www.exemple-verif.fr'
  Verify.evidence('admin-saisies-controlees', page, 'url-completee',
    "solution=#{solution.id} saisi=www.exemple-verif.fr en_base=#{solution.reload.site_internet}")
  solution.update!(site_internet: site_avant)

  integration = Integration.en_production.order(:id).first
  page.visit("/admin/integrations/#{integration.id}/edit")
  options = page.find_field('Statut de l’intégration').all('option').map(&:value)
  raise "options #{options}" unless options == ['', *Integration::STATUTS]

  page.select Integration::STATUT_EN_PRODUCTION, from: 'Statut de l’intégration'
  page.click_button 'Enregistrer'
  page.assert_text "« #{integration.libelle} » enregistré."
  Verify.evidence('admin-saisies-controlees', page, 'statut-liste',
    "integration=#{integration.id} options=#{options.size} en_base=#{integration.reload.statut}")

  organisation = solution.organisations.find_by!(public_ou_prive: 'Public')
  page.visit("/admin/organisations/#{organisation.id}/edit")
  page.assert_selector :radio_button, 'Public', checked: true, visible: :all
  Verify.evidence('admin-saisies-controlees', page, 'radios-public-prive')
  page.click_button 'Enregistrer'
  page.assert_text "« #{organisation.nom} » enregistré."
  page.visit("/solutions/#{solution.slug}")
  page.assert_text(/Solution publique \| #{Regexp.escape(organisation.nom)}/i)
  Verify.evidence('admin-saisies-controlees', page, 'solution-reste-publique',
    "organisation=#{organisation.id} en_base=#{organisation.reload.public_ou_prive} privee=#{solution.reload.privee?}")

  demarche = Demarche.visibles.order(:id).first
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Slug', with: 'Vérif avec espaces/et accents'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'
  page.assert_selector :field, 'Slug', with: 'Vérif avec espaces/et accents'
  Verify.evidence('admin-saisies-controlees', page, 'slug-refuse', "demarche=#{demarche.id} en_base=#{demarche.reload.slug}")
  page.visit("/demarches/#{demarche.slug}")
  page.assert_selector 'h1', text: demarche.nom
  Verify.evidence('admin-saisies-controlees', page, 'page-publique', "path=#{page.current_path}")
  Verify.logout(page)
end

def incoherences(page)
  Verify.login(page)
  integration = Integration.order(:id).first!
  page.visit("/admin/integrations/#{integration.id}/edit")
  page.select integration.integratrice.nom, from: 'API ou jeu de données'
  page.click_button 'Enregistrer'
  page.assert_text 'Une solution ne peut pas s’intégrer elle-même'
  Verify.evidence('admin-saisies-controlees', page, 'integration-elle-meme',
    "integration=#{integration.id} integratrice=#{integration.integratrice_id} integree_en_base=#{integration.reload.integree_id}")

  nom = "Vérif verify-map #{Verify.browser}"
  page.visit('/admin/vocabulaires/new')
  page.fill_in 'Nom', with: nom
  page.select 'Usager', from: 'Catégorie'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug doit être rempli'
  page.fill_in 'Slug', with: 'Vérif Accents'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'
  Verify.evidence('admin-saisies-controlees', page, 'vocabulaire-sans-slug', "en_base=#{Vocabulaire.where(nom:).count}")
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

def dates(page)
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  page.visit('/admin/demarches/new')
  page.assert_no_selector "[name='demarche[cree_le]'], [name='demarche[modifie_le]']"
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  demarche = ActiveRecord::Base.uncached { Demarche.find_by!(nom:) }
  creation = demarche.cree_le
  raise "dates a la creation #{creation.inspect} #{demarche.modifie_le.inspect}" unless creation&.after?(1.minute.ago) && demarche.modifie_le

  Verify.evidence('admin-dates', page, 'cree', "demarche=#{demarche.id} cree_le=#{creation.iso8601(3)} modifie_le=#{demarche.modifie_le.iso8601(3)}")
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Nom', with: "#{nom} modifiée"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} modifiée » enregistré."
  demarche.reload
  raise "modification non datee #{demarche.modifie_le.inspect}" unless demarche.modifie_le > creation && demarche.cree_le == creation

  Verify.evidence('admin-dates', page, 'modifie', "demarche=#{demarche.id} cree_le=#{demarche.cree_le.iso8601(3)} modifie_le=#{demarche.modifie_le.iso8601(3)}")
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.accept_confirm("Supprimer « #{nom} modifiée » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} modifiée » supprimé."
  Verify.evidence('admin-dates', page, 'supprime', "reste_en_base=#{ActiveRecord::Base.uncached { Demarche.where(id: demarche.id).count }}")
  Verify.logout(page)
end

def lecture_seule(page)
  Verify.login(page)
  demarche = Demarche.where.not(grist_id: nil).order(:id).first!
  page.visit("/admin/demarches/#{demarche.id}/edit")
  identifiant = page.find('p', text: "Identifiant Grist : #{demarche.grist_id}")
  page.scroll_to(identifiant, align: :center)
  page.assert_no_selector "[name='demarche[grist_id]']"
  Verify.evidence('admin-lecture-seule', page, 'identifiant-grist', "demarche=#{demarche.id} grist_id=#{demarche.grist_id} champ=0")
  solution = Solution.where.not(datagouv_titre: nil).order(:id).first!
  page.visit("/admin/solutions/#{solution.id}/edit")
  bloc = page.find('h2', text: 'Repris de data.gouv.fr').find(:xpath, '..')
  bloc.assert_text "Titre : #{solution.datagouv_titre}"
  champs = Solution::DATAGOUV.count { |champ| page.has_selector?("[name='solution[#{champ}]']", wait: 0) }
  raise "#{champs} champs data.gouv saisissables" unless champs.zero?

  page.scroll_to(bloc, align: :center)
  Verify.evidence('admin-lecture-seule', page, 'datagouv', "solution=#{solution.id} uid=#{solution.uid_datagouv} titre=#{solution.datagouv_titre} champs=0")
  Verify.logout(page)
end

def libelles_de(page)
  page.evaluate_script(<<~JS)
    Array.from(document.querySelectorAll('form[data-controller="formulaire-modifie"] :is(label, legend)'))
      .map((e) => Array.from(e.childNodes).filter((n) => n.nodeType === 3).map((n) => n.textContent).join('').trim())
      .filter(Boolean)
  JS
end

def libelles(page)
  Verify.login(page)
  reco = Recommandation.niveau_1.order(:id).first!
  page.visit("/admin/recommandations/#{reco.id}/edit")
  page.assert_selector :select, 'Type de recommandation', selected: 'Donnée utile (API ou jeu de données)'
  page.find('label', text: 'Type de recommandation').assert_text 'Solution recommandée : carte sur la page du cas d’usage'
  page.scroll_to(page.find_field('Type de recommandation'), align: :center)
  Verify.evidence('admin-libelles', page, 'recommandation', "reco=#{reco.id} niveau=#{reco.niveau} ordre=#{libelles_de(page).first(6).join(' | ')}")
  solution = Solution.where.not(uid_datagouv: [nil, '']).where.not(categorie: nil).order(:id).first!
  page.visit("/admin/solutions/#{solution.id}/edit")
  page.assert_selector :field, 'Identifiant data.gouv', with: solution.uid_datagouv
  categorie = Solution.human_attribute_name("categorie.#{solution.categorie}")
  page.assert_selector :select, 'Catégorie de solution', selected: categorie
  page.scroll_to(page.find_field('Identifiant data.gouv'), align: :center)
  Verify.evidence('admin-libelles', page, 'solution', "solution=#{solution.id} categorie=#{solution.categorie}→#{categorie} ordre=#{libelles_de(page).first(5).join(' | ')}")
  integration = Integration.consomme.order(:id).first!
  page.visit("/admin/integrations/#{integration.id}/edit")
  page.assert_selector :select, 'Type d’intégration', selected: 'Intégrée'
  Verify.evidence('admin-libelles', page, 'integration', "integration=#{integration.id} type=#{integration.type_integration} ordre=#{libelles_de(page).first(4).join(' | ')}")
  demarche = Demarche.order(:id).first!
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector :field, 'Mots-clés'
  Verify.evidence('admin-libelles', page, 'demarche', "demarche=#{demarche.id} ordre=#{libelles_de(page).first(8).join(' | ')}")
  Verify.logout(page)
end

Verify.ensure_admin
def pages_avec_html
  avec_html = ->(scope, *cols) { scope.where(cols.map { |c| "#{c} LIKE '%<%'" }.join(' OR ')) }
  demarches = avec_html.call(Demarche.visibles, :contexte, :cadre_juridique).pluck(:slug)
  recos = avec_html.call(Recommandation.where(visible: true), :donnees_utiles, :parametres_a_saisir, :description)
  solutions = avec_html.call(Solution.visibles.fiches, :permet, :ne_permet_pas).pluck(:slug)
  (demarches + Demarche.where(id: recos.select(:demarche_id)).pluck(:slug)).uniq.map { "/demarches/#{it}" } +
    solutions.map { "/solutions/#{it}" }
end

def contenu_html(page)
  page.visit('/demarches/actes-detat-civil')
  encadre = page.find('.fr-callout', text: 'Utilisez Comedec')
  encadre.scroll_to(encadre)
  Verify.evidence('contenu-html-grist', page, 'encadre-comedec', "encadre=#{encadre.tag_name}.fr-callout")
  page.visit('/solutions/passe-marche')
  separateur = page.find('hr:not([class])')
  separateur.scroll_to(separateur)
  Verify.evidence('contenu-html-grist', page, 'solution-hr', 'passe-marche hr_saisi=1')
  chemins = pages_avec_html
  omis = chemins.select do |chemin|
    page.visit(chemin)
    page.html.include?('raw HTML omitted')
  end
  raise "HTML omis sur #{omis.join(', ')}" if omis.any?

  Verify.evidence('contenu-html-grist', page, 'aucun-html-omis', "pages_avec_html=#{chemins.size} omis=0")
end

def lignes_affichees(page) = page.all('tbody tr').map { |ligne| ligne.all('td').map(&:text) }

def listes(page)
  dossier = 'admin-listes'
  Verify.login(page)
  page.click_link 'Solutions'
  page.assert_selector 'thead th', text: 'Intégrée par'
  entetes = page.all('thead th').map(&:text)
  raise "entetes #{entetes}" unless entetes == ['Id', 'Nom', 'Visible', 'Modifié le', 'Intégrée par']

  attendu = [(Solution.count / 50.0).ceil, 50].min
  raise "lignes page 1 #{lignes_affichees(page).size}" unless lignes_affichees(page).size == [Solution.count, 50].min

  Verify.evidence(dossier, page, 'solutions-page-1', "solutions=#{Solution.count} lignes=#{lignes_affichees(page).size} pages=#{attendu}")
  page.click_link 'Page 2'
  premiere = Solution.order(:id).offset(50).first
  page.assert_selector 'tbody tr:first-child td', text: premiere.nom
  Verify.evidence(dossier, page, 'solutions-page-2', "url=#{page.current_url.sub(%r{\Ahttps?://[^/]+}, '')} premiere=#{premiere.id}")
  integree = Solution.joins(:integrations_comme_integree).order(:id).first
  integratrice = integree.integratrices.min_by(&:nom)
  rechercher(page, integree.nom)
  noms = lignes_affichees(page).map(&:second)
  attendus = Solution.recherche(integree.nom).order(:id).limit(50).pluck(:nom)
  raise "recherche #{noms} != #{attendus}" unless noms == attendus

  Verify.evidence(dossier, page, 'solutions-recherche', "q=#{integree.nom} lignes=#{noms.size} en_base=#{Solution.recherche(integree.nom).count}")
  page.within(:xpath, "//tr[td[2][normalize-space()=#{integree.nom.inspect}]]") { page.click_link integratrice.nom, exact_text: true }
  page.assert_current_path("/admin/solutions/#{integratrice.id}/edit")
  Verify.evidence(dossier, page, 'integratrice-ouverte', "integree=#{integree.id} integratrice=#{integratrice.id} url=#{page.current_path}")
  page.click_link 'Administration', match: :first
  page.click_link 'Recommandations'
  reco = Recommandation.includes(:demarche, :solution).order(:id).first
  rechercher(page, "#{reco.demarche.nom.split.first} #{reco.solution.nom.split.last}")
  page.assert_selector 'tbody a', text: reco.libelle
  visibles = page.all('tbody tr').map { |ligne| ligne.all('td')[2].text }.tally
  Verify.evidence(dossier, page, 'recommandations-recherche', "q=#{page.find_field('Rechercher').value} lignes=#{lignes_affichees(page).size} visible=#{visibles}")
  Verify.logout(page)
end

def rechercher(page, texte)
  page.fill_in 'Rechercher', with: texte
  page.click_button 'Rechercher'
  page.assert_current_path(/[?&]q=/, url: true)
end

def ouvrir_depuis_la_liste(page, nom)
  rechercher(page, nom)
  page.within('tbody') { page.click_link nom, exact_text: true }
end

def ouvrir_fiche(page, nom)
  page.click_link 'Administration', match: :first
  page.click_link 'Démarches'
  ouvrir_depuis_la_liste(page, nom)
  page.find_field('Nom', with: nom)
end

def demande_avant_de_partir(page, question, &)
  message = page.dismiss_confirm(&)
  raise "confirmation #{message.inspect}" unless message == question
end

def formulaire_modifie(page)
  question = 'Quitter sans enregistrer les modifications ?'
  nom = "Vérif verify-map #{Verify.browser}"
  demarche = Demarche.create!(nom:)
  saisie = "#{nom} modifié"
  Verify.login(page)
  ouvrir_fiche(page, nom)
  page.click_link 'Annuler'
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence('admin-formulaire-modifie', page, 'annuler-sans-saisie', 'confirmation=aucune')

  ouvrir_fiche(page, nom)
  page.fill_in 'Nom', with: saisie
  demande_avant_de_partir(page, question) { page.click_link 'Annuler' }
  demande_avant_de_partir(page, question) { page.go_back }
  demande_avant_de_partir(page, question) { page.click_button 'Supprimer' }
  page.find_field('Nom', with: saisie)
  avertit = page.evaluate_script("(() => { const e = new Event('beforeunload', { cancelable: true }); dispatchEvent(e); return e.defaultPrevented })()")
  Verify.evidence('admin-formulaire-modifie', page, 'reste-sur-la-fiche',
    "url=#{page.current_path} champ=#{page.find_field('Nom').value} beforeunload_bloque=#{avertit} " \
    "en_base_apres_supprimer_refuse=#{Demarche.where(id: demarche.id).count}")
  page.dismiss_confirm(/^Supprimer/) { page.accept_confirm(question) { page.click_button 'Supprimer' } }
  demande_avant_de_partir(page, question) { page.click_link 'Annuler' }
  page.fill_in 'Nom', with: "#{saisie} encore"
  page.accept_confirm(question) { page.go_back }
  page.assert_selector 'h1', text: 'Démarches'
  page.go_forward
  page.find_field('Nom', with: nom)
  page.execute_script("window.fetch = () => Promise.reject(new TypeError('réseau coupé'))")
  page.fill_in 'Nom', with: saisie
  page.click_button 'Enregistrer'
  demande_avant_de_partir(page, question) { page.click_link 'Annuler' }
  Verify.evidence('admin-formulaire-modifie', page, 'reseau-coupe', "champ=#{page.find_field('Nom').value} confirmation=demandee")
  page.accept_confirm(question) { page.go_back }
  page.assert_selector 'h1', text: 'Démarches'
  ActiveRecord::Base.uncached do
    Verify.evidence('admin-formulaire-modifie', page, 'quitte', "nom_en_base=#{Demarche.find(demarche.id).nom}")
  end

  ouvrir_fiche(page, nom)
  page.fill_in 'Nom', with: ''
  page.click_button 'Enregistrer'
  page.assert_text 'Nom doit être rempli'
  demande_avant_de_partir(page, question) { page.click_link 'Annuler' }
  page.fill_in 'Nom', with: "#{nom} enregistré"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} enregistré » enregistré."
  ActiveRecord::Base.uncached do
    Verify.evidence('admin-formulaire-modifie', page, 'enregistre', "confirmation=aucune nom_en_base=#{Demarche.find(demarche.id).nom}")
  end

  ouvrir_fiche(page, "#{nom} enregistré")
  page.accept_confirm("Supprimer « #{nom} enregistré » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} enregistré » supprimé."
  ActiveRecord::Base.uncached do
    Verify.evidence('admin-formulaire-modifie', page, 'supprime', "confirmation=suppression_seule en_base=#{Demarche.where(id: demarche.id).count}")
  end
  Verify.logout(page)
ensure
  Demarche.where(id: demarche&.id).destroy_all
end

def erreurs(page)
  question = 'Quitter sans enregistrer les modifications ?'
  dossier = 'admin-erreurs-formulaire'
  avant = Demarche.count
  Verify.login(page)
  page.click_link 'Administration', match: :first
  page.click_link 'Démarches'
  page.click_link 'Ajouter'
  raise 'Nom sans required' unless page.find_field('Nom (obligatoire)')[:required]

  page.check 'Visible sur simplifions', allow_label_click: true
  page.click_button 'Enregistrer'
  recapitulatif = page.find('.fr-alert--error', text: '2 erreurs à corriger')
  focus = page.evaluate_script("document.activeElement.matches('.fr-alert--error')")
  raise 'focus hors du récapitulatif' unless focus

  liens = recapitulatif.all('a').map { |lien| "#{lien[:href].split('#').last}=#{lien.text}" }
  Verify.evidence(dossier, page, 'recapitulatif',
    "focus_recapitulatif=#{focus} liens=#{liens.join(' | ')} demarches_creees=#{Demarche.count - avant}")
  page.send_keys :tab
  premier = page.evaluate_script('document.activeElement.textContent')
  page.click_link 'Nom doit être rempli'
  cible = page.evaluate_script('[location.hash, document.activeElement.id]')
  champ = page.find_field('Nom (obligatoire)')
  message = page.find("##{champ['aria-describedby']}").text
  Verify.evidence(dossier, page, 'champ',
    "tab=#{premier} hash=#{cible[0]} focus=#{cible[1]} aria_invalid=#{champ['aria-invalid']} message=#{message}")
  demande_avant_de_partir(page, question) { page.click_link 'Annuler' }

  page.visit('/admin/recommandations/new')
  page.click_button 'Enregistrer'
  page.assert_text 'Choisissez une démarche'
  messages = page.all('.fr-select-group--error .fr-message--error').map(&:text)
  Verify.evidence(dossier, page, 'recommandation', "messages=#{messages.join(' | ')} recommandations_creees=0")
  page.current_window.resize_to(640, 1024)
  Verify.evidence(dossier, page, 'etroit', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  page.accept_confirm(question) { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

{ 'catalogue' => :catalogue, 'fiche' => :fiche, 'connexion' => :connexion, 'vocabulaires' => :vocabulaires,
  'cascade' => :cascade, 'saisies' => :saisies, 'contenu-html' => :contenu_html,
  'incoherences' => :incoherences, 'dates' => :dates, 'lecture-seule' => :lecture_seule,
  'formulaire-modifie' => :formulaire_modifie, 'libelles' => :libelles,
  'erreurs' => :erreurs, 'listes' => :listes }.each do |nom, fn|
  next if only && only != nom

  method(fn).call(page)
  puts "ok #{nom}"
rescue StandardError => e
  Verify.evidence(nom, page, 'echec')
  puts "ECHEC #{nom}: #{e.class} #{e.message}"
end
page.quit
