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
  Recommandation.create!(demarche:, solution:, niveau: :niveau_1)
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
  privees = organisation.solutions_rendues_privees.map(&:libelle_admin)
  page.visit("/admin/organisations/#{organisation.id}/edit")
  message = page.dismiss_confirm { page.click_button 'Supprimer' }
  raise "confirmation #{message}" unless privees.all? { |libelle| message.include?(libelle) }

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
  page.assert_text "« #{solution.libelle_admin} » enregistré."
  page.visit("/solutions/#{solution.slug}")
  page.assert_selector :link, 'Site de la solution', href: 'https://www.exemple-verif.fr'
  Verify.evidence('admin-saisies-controlees', page, 'url-completee',
    "solution=#{solution.id} saisi=www.exemple-verif.fr en_base=#{solution.reload.site_internet}")
  solution.update!(site_internet: site_avant)

  integration = Integration.en_production.order(:id).first
  page.visit("/admin/integrations/#{integration.id}/edit")
  options = page.find_field('Statut de l’intégration').all('option').map(&:value)
  raise "options #{options}" unless options == ['', *Integration::STATUTS]

  page.find_field('Statut de l’intégration').find('option[value=""]').select_option
  page.select Integration::STATUT_EN_PRODUCTION, from: 'Statut de l’intégration'
  page.click_button 'Enregistrer'
  page.assert_text "« #{integration.libelle} » enregistré."
  Verify.evidence('admin-saisies-controlees', page, 'statut-liste',
    "integration=#{integration.id} options=#{options.size} en_base=#{integration.reload.statut}")

  organisation = solution.organisations.find_by!(public_ou_prive: 'Public')
  page.visit("/admin/organisations/#{organisation.id}/edit")
  page.assert_selector :radio_button, 'Public', checked: true, visible: :all
  Verify.evidence('admin-saisies-controlees', page, 'radios-public-prive')
  page.fill_in 'organisation[nom]', with: organisation.nom
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
  page.select integration.integratrice.libelle_admin, from: 'API ou jeu de données'
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
  raise "entetes #{entetes}" unless entetes == ['Id', 'Nom', 'Privée', 'Visible', 'Modifié le', 'Intégrée par']

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
  attendus = Solution.recherche(integree.nom).order(:id).limit(50).map(&:libelle_admin)
  raise "recherche #{noms} != #{attendus}" unless noms == attendus

  Verify.evidence(dossier, page, 'solutions-recherche', "q=#{integree.nom} lignes=#{noms.size} en_base=#{Solution.recherche(integree.nom).count}")
  page.within(:xpath, "//tr[td[2][normalize-space()=#{integree.libelle_admin.inspect}]]") { page.click_link integratrice.libelle_admin, exact_text: true }
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

def listes_lisibles(page)
  dossier = 'admin-listes'
  Verify.login(page)
  rubriques = %w[Catalogue Référentiels].to_h { |titre| [titre, page.find('h2', text: titre).find(:xpath, 'following-sibling::ul[1]').all('a').map(&:text)] }
  raise "rubriques #{rubriques}" unless rubriques['Référentiels'] == ['Fournisseurs de services', 'Vocabulaires']

  Verify.evidence(dossier, page, 'accueil-rubriques', rubriques.map { |titre, liens| "#{titre}=#{liens.join('|')}" }.join(' '))
  page.click_link 'Organisations'
  raise 'pagination organisations' if page.has_css?('.fr-pagination', wait: 0)
  raise "organisations #{lignes_affichees(page).size} != #{Organisation.count}" unless lignes_affichees(page).size == Organisation.count

  organisation = Organisation.where.not(nom_long: [nil, '']).order(:id).first
  page.assert_selector 'tbody tr', text: "#{organisation.nom} #{organisation.nom_long}"
  Verify.evidence(dossier, page, 'organisations-une-page', "lignes=#{lignes_affichees(page).size} en_base=#{Organisation.count} nom_long=#{organisation.nom_long}")
  page.click_link 'Administration', match: :first
  page.click_link 'Intégrations'
  integration = Integration.includes(:integratrice, :integree).order(:id).first
  attendu = [integration.id.to_s, integration.integratrice.libelle_admin, integration.integree.libelle_admin, integration.type_libelle, integration.statut.to_s]
  raise "entetes #{page.all('thead th').map(&:text)}" unless page.all('thead th').map(&:text) == ['Id', 'Solution', 'API ou jeu de données', 'Type d’intégration', 'Statut de l’intégration']
  raise "intégration #{lignes_affichees(page).first} != #{attendu}" unless lignes_affichees(page).first == attendu

  Verify.evidence(dossier, page, 'integrations-colonnes', "premiere=#{attendu.join(' | ')}")
  page.click_link 'Administration', match: :first
  page.click_link 'Démarches'
  demarche = Demarche.where.not(icone: [nil, '']).order(:id).first
  rechercher(page, demarche.nom)
  cellule = page.find(:xpath, "//tbody//td[a[normalize-space()=#{demarche.nom.inspect}]]")
  raise "icône #{cellule.text}" unless cellule.text == "#{demarche.icone} #{demarche.nom}" && cellule.has_css?('[aria-hidden=true]', text: demarche.icone)

  Verify.evidence(dossier, page, 'demarche-icone', "demarche=#{demarche.id} cellule=#{cellule.text}")
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

def cases_affichees(groupe) = groupe.all('[data-liste-filtrable-target=element]:not(.fr-hidden) input', visible: :all)

def liste_filtrable(page)
  dossier = 'admin-liste-filtrable'
  nom = "Vérif verify-map #{Verify.browser}"
  integrations = Integration.includes(:integratrice, :integree).order(:id).to_a
  demarche = Demarche.create!(nom:, integrations: integrations.first(2))
  cible = integrations.last
  Verify.login(page)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  categories = page.all('fieldset fieldset > legend').map(&:text)
  raise "groupes de vocabulaires #{categories}" unless categories == ['Usager', 'Type de simplification', 'Catégorie de solution']

  raise 'lien sous un vocabulaire' if page.find('fieldset', text: 'Vocabulaires', match: :first).has_link?('Voir la fiche', wait: 0)

  groupe = page.find('fieldset', text: 'Filtrer les intégrations')
  coches = cases_affichees(groupe)
  raise "cases visibles sans filtre #{coches.size}" unless coches.size == 2 && coches.all?(&:checked?)

  compte = groupe.find('[aria-live=polite]').text
  raise "compte #{compte}" unless compte == "2 cochés sur #{integrations.size}"

  Verify.evidence(dossier, page, 'cochees-seules', "visibles=#{coches.size} compte=#{compte} en_base=#{demarche.integration_ids.size} vocabulaires=#{categories.join(' | ')}")
  page.execute_script("document.querySelectorAll('input[name=\"demarche[vocabulaire_ids][]\"]:not([type=hidden])').forEach((c, i, l) => i === l.length - 1 && c.focus())")
  page.send_keys :tab
  raise 'Tab n’entre pas dans le filtre' unless page.evaluate_script('document.activeElement.id') == 'demarche_integration_ids_filtre'
  raise 'Tab a ouvert la liste' unless cases_affichees(groupe).size == 2

  tabs = (1..10).find do
    page.send_keys :tab
    !page.evaluate_script("document.activeElement.closest('[data-controller=liste-filtrable]') === arguments[0]", groupe)
  end
  raise "#{tabs} Tab pour traverser la liste" unless tabs == 6

  Verify.evidence(dossier, page, 'traversee-au-clavier', "tabs_du_filtre_a_la_suite=#{tabs} visibles=2")
  resultats = groupe.find('[data-liste-filtrable-target=resultats]')
  fond = -> { page.evaluate_script('getComputedStyle(arguments[0]).backgroundColor', resultats) }
  sans_cadre = fond.call
  groupe.find_field('Filtrer les intégrations').click
  tous = cases_affichees(groupe).size
  raise "cases visibles au clic #{tous}" unless tous == integrations.size
  raise 'compte changé au clic' unless groupe.find('[aria-live=polite]').text == compte
  raise "pas de cadre gris (#{fond.call})" if fond.call == sans_cadre

  Verify.evidence(dossier, page, 'tous-au-clic-encadres', "visibles=#{tous} total=#{integrations.size} fond=#{fond.call} fond_ferme=#{sans_cadre}")
  groupe.fill_in 'Filtrer les intégrations', with: 'zzz'
  groupe.click_button 'Effacer le filtre des intégrations'
  raise 'croix : filtre non vide' unless groupe.find_field('Filtrer les intégrations').value == ''
  raise "croix : #{cases_affichees(groupe).size} cases" unless cases_affichees(groupe).size == 2 && fond.call == sans_cadre
  raise 'croix : focus perdu' unless page.evaluate_script('document.activeElement.id') == 'demarche_integration_ids_filtre'

  Verify.evidence(dossier, page, 'croix-referme', "visibles=#{cases_affichees(groupe).size} fond=#{fond.call}")
  page.send_keys :down
  raise 'flèche bas n’ouvre pas' unless cases_affichees(groupe).size == integrations.size

  page.send_keys %i[shift tab]
  raise "sortie : #{cases_affichees(groupe).size} cases" unless cases_affichees(groupe).size == 2 && fond.call == sans_cadre

  Verify.evidence(dossier, page, 'fleche-bas-puis-sortie-referme', "visibles=#{cases_affichees(groupe).size}")
  saisie = I18n.transliterate(cible.libelle).upcase.scan(/[[:alnum:]]+/).join(' ')
  groupe.fill_in 'Filtrer les intégrations', with: saisie
  groupe.find('label', text: cible.libelle, exact_text: true)
  page.send_keys :enter
  raise 'Entrée a envoyé le formulaire' if page.has_text?('enregistré', wait: 1)

  case_cible = "demarche_integration_ids_#{cible.id}"
  20.times do
    break if page.evaluate_script('document.activeElement.id') == case_cible

    page.send_keys :tab
  end
  raise 'case cible jamais atteinte au clavier' unless page.evaluate_script('document.activeElement.id') == case_cible

  page.send_keys :space
  compte = groupe.find('[aria-live=polite]').text
  Verify.evidence(dossier, page, 'filtre-et-coche-au-clavier', "saisie=#{saisie} compte=#{compte}")
  groupe.fill_in 'Filtrer les intégrations', with: ''
  raise 'cible cachée après effacement' unless cases_affichees(groupe).select(&:checked?).map { |c| c[:id] }.include?(case_cible)

  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  ActiveRecord::Base.uncached do
    Verify.evidence(dossier, page, 'enregistre', "en_base=#{Demarche.find(demarche.id).integration_ids.sort} cible=#{cible.id}")
  end
  page.find('fieldset', text: 'Filtrer les intégrations').fill_in 'Filtrer les intégrations', with: 'texte sans nom'
  page.click_link 'Annuler'
  page.assert_selector 'h1', text: 'Démarches'
  Verify.evidence(dossier, page, 'filtre-ignore-en-partant', 'confirmation=aucune')
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

  page.click_button 'Publier'
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
  page.click_button 'Publier'
  page.assert_text 'Choisissez une démarche'
  messages = page.all('.fr-select-group--error .fr-message--error').map(&:text)
  Verify.evidence(dossier, page, 'recommandation', "messages=#{messages.join(' | ')} recommandations_creees=0")
  page.current_window.resize_to(640, 1024)
  Verify.evidence(dossier, page, 'etroit', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  page.accept_confirm(question) { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

def homonymes(page)
  dossier = 'admin-homonymes'
  nom = 'API Impôt particulier'
  Verify.login(page)
  page.visit('/admin/recommandations/new')
  options = page.all('#recommandation_solution_id option', text: nom).map(&:text)
  raise "options recommandation #{options}" unless options.size == 2 && options.uniq.size == 2

  Verify.evidence(dossier, page, 'recommandation', "options=#{options.join(' | ')} en_base=#{Solution.where(nom:).pluck(:categorie).join(',')}")
  page.visit('/admin/integrations/new')
  integrees = page.all('#integration_integree_id option', text: nom).map(&:text)
  raise "options intégration #{integrees}" unless integrees == options

  Verify.evidence(dossier, page, 'integration', "integree=#{integrees.join(' | ')}")
  page.visit('/admin/types_acteurs/new')
  groupe = page.find('fieldset', text: 'Filtrer les solutions')
  groupe.fill_in 'Filtrer les solutions', with: 'impot particulier'
  cases = groupe.all('[data-liste-filtrable-target=element]:not(.fr-hidden) label').map(&:text)
  raise "cases #{cases}" unless cases.sort == options.sort

  Verify.evidence(dossier, page, 'cases-filtrables', "cases=#{cases.join(' | ')}")
  page.visit('/admin/solutions')
  page.fill_in 'Rechercher', with: 'impot particulier'
  page.click_button 'Rechercher'
  page.assert_current_path(/q=/)
  integree_par = page.all('tbody tr').map { |ligne| ligne.all('td').last.text }.reject(&:empty?)
  raise "intégrée par #{integree_par}" unless integree_par.any? { |cellule| cellule.include?("#{nom} (") }

  Verify.evidence(dossier, page, 'integree-par', "integree_par=#{integree_par.join(' / ')}")
  Verify.logout(page)
end

def zone_sans_defilement(page, id)
  page.evaluate_script("(z => [z.rows, z.scrollHeight, z.clientHeight, z.scrollHeight <= z.clientHeight + 2])(document.getElementById('#{id}'))")
end

def lien_nomme(zone, nom) = zone.all('a').find { |lien| lien['aria-label'] == nom } || raise("aucun lien nommé #{nom}")

def pages_liees(page)
  dossier = 'admin-pages-liees'
  demarche = Demarche.visibles.where.not(slug: [nil, '']).max_by { |ligne| ligne.contexte.to_s.size }
  Verify.login(page)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  zone = zone_sans_defilement(page, 'demarche_contexte')
  raise "contexte défile #{zone}" unless zone.last

  aide = page.find('label[for=demarche_contexte] .fr-hint-text').text
  raise "aide #{aide}" unless aide == 'Markdown accepté'

  Verify.evidence(dossier, page, 'zone-de-texte', "caracteres=#{demarche.contexte.size} rows,scrollHeight,clientHeight,sans_defilement=#{zone.join(',')} aide=#{aide}")
  lien = page.find_link('Voir la page publique')
  publique = page.window_opened_by { lien.click }
  titre = page.within_window(publique) do
    page.assert_current_path("/demarches/#{demarche.slug}")
    page.find('h1').text
  end
  Verify.evidence(dossier, page, 'page-publique', "title=#{lien[:title]} target=#{lien[:target]} ouvert=/demarches/#{demarche.slug} h1=#{titre}")
  publique.close

  acteur = demarche.types_acteurs.order(:nom).first
  groupe = page.find('fieldset', text: 'Filtrer les fournisseurs de services')
  liens = groupe.all('a', text: 'Voir la fiche').map { |a| a['aria-label'] }
  raise "liens #{liens} pour #{demarche.types_acteurs.map(&:nom)}" unless liens.sort == demarche.types_acteurs.map { |t| "Voir la fiche #{t.nom}" }.sort

  Verify.evidence(dossier, page, 'liens-cases-cochees', "liens=#{liens.join(' | ')}")
  lien_nomme(groupe, "Voir la fiche #{acteur.nom}").click
  page.assert_selector 'h1', text: acteur.nom
  page.assert_current_path("/admin/types_acteurs/#{acteur.id}")
  Verify.evidence(dossier, page, 'fiche-liee', "url=#{page.current_path} h1=#{page.find('h1').text}")

  recommandation = Recommandation.first
  page.visit("/admin/recommandations/#{recommandation.id}/edit")
  lien_nomme(page, "Voir la fiche #{recommandation.solution.libelle_admin}").click
  page.assert_current_path("/admin/solutions/#{recommandation.solution_id}/edit")
  Verify.evidence(dossier, page, 'recommandation-vers-solution', "url=#{page.current_path} h1=#{page.find('h1').text}")
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.evidence(dossier, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  groupe = page.find('fieldset', text: 'Filtrer les fournisseurs de services')
  groupe.fill_in 'Filtrer les fournisseurs de services', with: 'voir la fiche'
  filtre = cases_affichees(groupe).size
  raise "le filtre trouve le texte du lien (#{filtre})" unless filtre.zero?

  Verify.evidence(dossier, page, 'filtre-ignore-le-lien', "saisie=voir la fiche cases_affichees=#{filtre}")
  page.current_window.resize_to(1280, 1024)
  Verify.logout(page)
end

def recommandations_demarche(page)
  dossier = 'admin-recommandations-demarche'
  demarche = Demarche.visibles.max_by { |ligne| ligne.recommandations.count }
  solution = Solution.where(categorie: 'api').where.not(id: demarche.recommandations.select(:solution_id)).reject(&:privee?).first
  avant = demarche.recommandations.count
  Verify.login(page)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  lignes = page.find('table[aria-labelledby=recommandations]').all('tbody tr').size
  raise "#{lignes} lignes pour #{avant} recommandations" unless lignes == avant

  Verify.evidence(dossier, page, 'demarche', "lignes=#{lignes} en_base=#{avant}")
  page.click_link 'Ajouter une recommandation'
  choisie = page.find('#recommandation_demarche_id option[selected]').text
  raise "démarche pré-remplie #{choisie}" unless choisie == demarche.nom

  autres = page.find('table[aria-labelledby=autres-recommandations]', visible: :all).all('tbody tr', visible: :all).size
  Verify.evidence(dossier, page, 'nouvelle', "demarche=#{choisie} autres=#{autres}")
  page.select solution.libelle_admin, from: 'Solution (obligatoire)'
  page.select 'Donnée utile (API ou jeu de données)', from: 'Type de recommandation'
  page.fill_in 'Ordre', with: '99'
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  creee = ActiveRecord::Base.uncached { demarche.recommandations.find_by!(solution:) }
  page.assert_current_path("/admin/recommandations/#{creee.id}/edit")
  encart = page.find('aside.fr-callout')
  encart.find('button', text: 'Autres recommandations de la démarche').click
  encart.assert_selector('table[aria-labelledby=autres-recommandations]', visible: true)
  Verify.evidence(dossier, page, 'enregistree', "url=#{page.current_path} encart=#{encart.find('h2').text} autres=#{encart.all('tbody tr', visible: :all).size} en_base=#{ActiveRecord::Base.uncached { demarche.recommandations.count }}")
  lien_nomme(encart, "Voir la fiche #{demarche.nom}").click
  page.assert_current_path("/admin/demarches/#{demarche.id}/edit")
  derniere = page.find('table[aria-labelledby=recommandations]').all('tbody tr').map { |ligne| ligne.all('td').map(&:text) }
    .find { |cellules| cellules.first == solution.libelle_admin }
  raise 'nouvelle recommandation absente de la démarche' unless derniere

  Verify.evidence(dossier, page, 'retour-demarche', "ligne=#{derniere.first(3).join(' | ')}")
  page.click_link solution.libelle_admin
  page.accept_confirm { page.click_button 'Supprimer' }
  page.assert_current_path('/admin/recommandations')
  Verify.evidence(dossier, page, 'supprimee', "en_base=#{ActiveRecord::Base.uncached { demarche.recommandations.count }} attendu=#{avant}")
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/recommandations/#{demarche.recommandations.first.id}/edit")
  Verify.evidence(dossier, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  Verify.logout(page)
end

def champ_masque(page, id)
  page.evaluate_script("(c => [!!c.closest('.fr-hidden'), c.disabled])(document.getElementById('#{id}'))")
end

def formulaire_solution(page)
  dossier = 'admin-formulaire-solution'
  nom = "Vérif verify-map #{Verify.browser}"
  solution = Solution.new(nom:, categorie: 'brique_logicielle', legende_image: 'Écran de vérification')
  solution.image.attach(io: Rails.root.join('app/assets/images/solutions/bouquet-api-entreprise.png').open, filename: 'verif.png')
  solution.save!
  Verify.login(page)
  page.visit('/admin/solutions')
  rechercher(page, nom)
  privee = page.find('tbody tr', text: nom).all('td')[2][:textContent].strip
  Verify.evidence(dossier, page, 'liste', "colonne_privee=#{privee} en_base=#{solution.privee?}")
  page.click_link solution.libelle_admin
  badge = page.find('h1 + .fr-badge')[:textContent].strip
  alt = page.find('.fr-upload-group img')['alt']
  aide = page.find('label[for=solution_image] .fr-hint-text').text
  raise "badge=#{badge} alt=#{alt} aide=#{aide}" unless badge == 'Privée' && alt == solution.legende_image && aide.include?('png, jpg, webp')

  Verify.evidence(dossier, page, 'fiche', "badge=#{badge} alt=#{alt} aide=#{aide} description_masquee,desactivee=#{champ_masque(page, 'solution_description_courte')}")
  page.select 'API', from: 'Catégorie de solution'
  etat = %w[solution_slug solution_description_courte solution_legende_image solution_retirer_image].to_h { |id| [id, champ_masque(page, id)] }
  attendu = { 'solution_slug' => [true, true], 'solution_description_courte' => [true, true],
              'solution_legende_image' => [false, false], 'solution_retirer_image' => [false, false] }
  raise "API : #{etat}" unless etat == attendu

  demande_avant_de_partir(page, 'Quitter sans enregistrer les modifications ?') { page.click_link 'Annuler' }
  Verify.evidence(dossier, page, 'api-choisie', "masque,desactive=#{etat} confirmation=demandee")
  page.select 'Brique technique', from: 'Catégorie de solution'
  masque = champ_masque(page, 'solution_description_courte')
  raise "brique : description #{masque}" unless masque == [false, false]

  Verify.evidence(dossier, page, 'brique-rechoisie', "description_masquee,desactivee=#{masque}")
  page.fill_in 'Légende de l’image', with: ''
  page.check 'Retirer l’image', allow_label_click: true
  page.select 'API', from: 'Catégorie de solution'
  etat = %w[solution_legende_image solution_retirer_image].to_h { |id| [id, champ_masque(page, id)] }
  raise "vidés puis API : #{etat}" unless etat.values.all?([false, false])

  Verify.evidence(dossier, page, 'vides-puis-api', "masque,desactive=#{etat}")
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  ActiveRecord::Base.uncached do
    en_base = Solution.find(solution.id)
    Verify.evidence(dossier, page, 'api-enregistree', "categorie=#{en_base.categorie} legende=#{en_base.legende_image.inspect} image=#{en_base.image.attached?} " \
      "legende_masquee,desactivee=#{champ_masque(page, 'solution_legende_image')} badge=#{page.has_css?('h1 + .fr-badge', wait: 0)}")
  end
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/solutions/#{solution.id}/edit")
  Verify.evidence(dossier, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  Verify.logout(page)
ensure
  Solution.where(id: solution&.id).destroy_all
end

def elements_lies(page)
  page.all('#elements-lies h3').to_h { |titre| [titre.text, titre.find(:xpath, 'following-sibling::ul[1]').all('a').map(&:text)] }
end

def types_coches(page) = page.all('input[name="solution[types_solution][]"]', visible: :all).select(&:checked?).map(&:value)

def saisie_solution(page)
  dossier = 'admin-saisie-solution'
  nom = "Vérif verify-map #{Verify.browser}"
  api = Solution.visibles.categorie_api.joins(:integrations_comme_integree).distinct.order(:id).first
  demarche = Demarche.visibles.order(:id).first
  solution = Solution.new(nom:, categorie: 'brique_logicielle', legende_image: 'Écran de vérification',
                          organisations: [Organisation.where(public_ou_prive: 'Public').order(:id).first])
  solution.image.attach(io: Rails.root.join('app/assets/images/solutions/bouquet-api-entreprise.png').open, filename: 'verif.png')
  solution.save!
  Integration.create!(integratrice: solution, integree: api, type_integration: 'consomme')
  Recommandation.create!(demarche:, solution:, niveau: :niveau_2)
  Verify.login(page)
  page.visit("/admin/solutions/#{solution.id}/edit")
  legende = page.find_field('Légende de l’image')
  aide = page.find('label[for=solution_retirer_image] .fr-hint-text').text
  lies = elements_lies(page)
  attendu = { 'Démarches qui la recommandent' => [demarche.nom], 'Ce qu’elle intègre' => [api.libelle_admin] }
  raise "legende=#{legende.tag_name}/#{legende[:type]} aide=#{aide} lies=#{lies}" unless
    legende[:type] == 'text' && aide == 'L’image sera retirée à l’enregistrement.' && lies == attendu

  Verify.evidence(dossier, page, 'fiche', "legende=#{legende.tag_name}[type=#{legende[:type]}] aide_retirer=#{aide} lies=#{lies}")
  page.find('#elements-lies').click_link api.libelle_admin
  page.assert_selector 'h1', text: api.libelle_admin
  integratrices = elements_lies(page)['Solutions qui l’intègrent']
  base = api.integratrices.par_libelle_admin.map { |integratrice| integratrice.libelle_admin.squish }
  raise "integratrices #{integratrices} != #{base}" unless integratrices == base && integratrices.include?(solution.libelle_admin)

  Verify.evidence(dossier, page, 'api-liee', "url=#{page.current_path} integratrices_page=#{integratrices.size} base=#{base.size} inclut_verif=true")
  page.visit("/admin/solutions/#{solution.id}/edit")
  libelles = page.all('#solution_types_solution .fr-label', visible: :all).map { |label| label[:textContent].strip }
  raise "cases #{libelles}" unless libelles == Solution::TYPES_SOLUTION

  page.check 'Portail agent', allow_label_click: true
  page.check "Hub d'échange", allow_label_click: true
  page.find('#solution_types_solution input[value="Portail agent"]', visible: :all).execute_script('this.focus()')
  page.send_keys(:tab)
  focus = page.evaluate_script('document.activeElement.value')
  Verify.evidence(dossier, page, 'cases-cochees', "cases=#{libelles.size} cochees=#{types_coches(page)} tab_apres_portail_agent=#{focus}")
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  enregistres = ActiveRecord::Base.uncached { Solution.find(solution.id).types_solution }
  raise "base #{enregistres}" unless enregistres == ['Portail agent', "Hub d'échange"]

  Verify.evidence(dossier, page, 'enregistre', "base=#{enregistres} cochees_page=#{types_coches(page)}")
  page.uncheck 'Portail agent', allow_label_click: true
  page.click_button 'Enregistrer'
  page.assert_text 'enregistré'
  enregistres = ActiveRecord::Base.uncached { Solution.find(solution.id).types_solution }
  raise "base apres decoche #{enregistres}" unless enregistres == ["Hub d'échange"]

  Verify.evidence(dossier, page, 'decoche', "base=#{enregistres} cochees_page=#{types_coches(page)}")
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/solutions/#{solution.id}/edit")
  Verify.evidence(dossier, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  Verify.logout(page)
ensure
  Solution.where(id: solution&.id).destroy_all
end

def definition(page, terme) = page.find('dt', text: terme, exact_text: true).find(:xpath, 'following-sibling::dd[1]').text

def cases_cochees(page) = page.find('fieldset', text: 'Regroupements', match: :first).all('input[type=checkbox]', visible: :all).select(&:checked?).map(&:value)

def fournisseurs(page)
  dossier = 'admin-fournisseurs-de-services'
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  page.click_link 'Fournisseurs de services'
  page.assert_selector 'h1', text: 'Fournisseurs de services'
  reel = TypeActeur.where.not(slugs: []).order(:id).first
  ouvrir_depuis_la_liste(page, reel.nom)
  page.assert_current_path("/admin/types_acteurs/#{reel.id}")
  lu = definition(page, 'Regroupements')
  raise "fiche #{lu}" unless lu == reel.regroupements.join(', ')

  Verify.evidence(dossier, page, 'consultation', "url=#{page.current_path} regroupements=#{lu} base=#{reel.slugs.join(',')}")
  page.click_link 'Modifier'
  page.assert_current_path("/admin/types_acteurs/#{reel.id}/edit")
  raise "cochées #{cases_cochees(page)} != #{reel.slugs}" unless cases_cochees(page).sort == (reel.slugs & TypeActeur::FILTRES.values).sort

  memos = %w[description codes_juridiques].map { |champ| page.find("label[for=type_acteur_#{champ}] .fr-hint-text").text }
  raise "mémos #{memos}" unless memos.uniq == ['Mémo interne, non affiché sur le site']

  Verify.evidence(dossier, page, 'formulaire', "cochees=#{cases_cochees(page).join(',')} memos=#{memos.uniq.first}")
  page.visit('/admin/types_acteurs/new')
  page.fill_in 'Nom', with: nom
  page.check 'Régions', allow_label_click: true
  page.check 'Tous les acteurs publics', allow_label_click: true
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  ligne = TypeActeur.find_by!(nom:)
  page.assert_current_path("/admin/types_acteurs/#{ligne.id}")
  Verify.evidence(dossier, page, 'cree', "url=#{page.current_path} slugs=#{ligne.slugs.join(',')} affiche=#{definition(page, 'Regroupements')} onglet=#{page.title}")
  page.click_link 'Modifier'
  page.uncheck 'Régions', allow_label_click: true
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  slugs = ActiveRecord::Base.uncached { TypeActeur.find(ligne.id).slugs }
  raise "slugs #{slugs}" unless slugs == %w[tout-acteurs-publics]

  Verify.evidence(dossier, page, 'decoche', "url=#{page.current_path} slugs=#{slugs.join(',')} affiche=#{definition(page, 'Regroupements')}")
  page.click_link 'Fournisseurs de services', match: :first
  rechercher(page, nom)
  colonne = page.find('tbody tr', text: nom).all('td').last.text
  raise "colonne #{colonne}" unless colonne == 'Tous les acteurs publics'

  Verify.evidence(dossier, page, 'liste', "regroupements=#{colonne}")
  page.visit("/admin/types_acteurs/#{ligne.id}/edit")
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  Verify.evidence(dossier, page, 'supprime', "reste_en_base=#{TypeActeur.where(nom:).count}")
  Verify.logout(page)
ensure
  TypeActeur.where(nom:).destroy_all
end

def visible_a_l_ecran?(page, bouton)
  page.evaluate_script(<<~JS, bouton)
    (function(el) { const r = el.getBoundingClientRect(); return r.top >= 0 && r.bottom <= innerHeight && document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) === el })(arguments[0])
  JS
end

def colonne(page)
  dossier = 'admin-colonne-actions'
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Verify.login(page)
  longue = Demarche.find(1)
  page.visit("/admin/demarches/#{longue.id}/edit")
  hauteur = page.evaluate_script('document.documentElement.scrollHeight')
  page.scroll_to(0, 14_000)
  page.assert_selector 'aside.admin-panneau', text: /Publiée/i
  enregistrer = page.find_button('Enregistrer', disabled: true)
  defilement = page.evaluate_script('window.scrollY')
  raise "Enregistrer hors écran à #{defilement}" unless visible_a_l_ecran?(page, enregistrer)

  Verify.evidence(dossier, page, 'defile', "demarche=#{longue.id} hauteur=#{hauteur} scrollY=#{defilement} enregistrer_a_l_ecran=true")

  demarche = Demarche.create!(nom:, slug:)
  ouvrir_fiche(page, nom)
  page.find_button('Enregistrer', disabled: true)
  page.find_button('Publier', disabled: false)

  Verify.evidence(dossier, page, 'enregistrer-grise', 'enregistrer=desactive publier=actif')
  page.fill_in 'Nom', with: "#{nom} saisie"
  page.find_button('Enregistrer', disabled: false)
  Verify.evidence(dossier, page, 'enregistrer-actif', 'enregistrer=actif apres_saisie')
  page.find_field('Nom').send_keys(:enter)
  page.assert_text "« #{nom} saisie » enregistré."
  etat = ActiveRecord::Base.uncached { demarche.reload.slice(:nom, :visible) }
  raise "entrée #{etat}" unless etat == { 'nom' => "#{nom} saisie", 'visible' => false }

  page.assert_selector 'aside.admin-panneau', text: /Masquée/i
  Verify.evidence(dossier, page, 'entree', "entree_garde_l_etat=#{etat}")
  page.find_button('Enregistrer', disabled: true)
  page.fill_in 'Nom', with: ''
  page.click_button 'Enregistrer'
  page.assert_text 'Nom doit être rempli'
  page.find_button('Enregistrer', disabled: false)
  Verify.evidence(dossier, page, 'erreur-enregistrer-actif', 'enregistrer=actif sur_formulaire_en_erreur')
  page.fill_in 'Nom', with: nom
  page.scroll_to(0, 2_000)
  page.click_button 'Publier'
  page.assert_text "« #{nom} » enregistré."
  page.assert_selector 'aside.admin-panneau', text: /Publiée/i
  etat = ActiveRecord::Base.uncached { demarche.reload.slice(:nom, :visible) }
  raise "publier #{etat}" unless etat == { 'nom' => nom, 'visible' => true }

  Verify.evidence(dossier, page, 'publiee', "base=#{etat}")
  publique = page.window_opened_by { page.click_link 'Voir la page publique' }
  titre = page.within_window(publique) do
    page.assert_current_path("/demarches/#{slug}")
    page.find('h1').text
  end
  publique.close
  Verify.evidence(dossier, page, 'page-publique', "h1=#{titre}")
  page.click_button 'Masquer'
  page.assert_selector 'aside.admin-panneau', text: /Masquée/i
  etat = ActiveRecord::Base.uncached { demarche.reload.visible }
  raise "masquer #{etat}" if etat

  Verify.evidence(dossier, page, 'masquee', "visible=#{etat}")

  page.current_window.resize_to(375, 800)
  debord = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')
  ordre = page.evaluate_script("document.querySelector('aside.admin-panneau').getBoundingClientRect().top < document.getElementById('formulaire-fiche').getBoundingClientRect().top")
  raise "375 px : débord #{debord}, colonne avant le formulaire #{ordre}" unless debord <= 0 && ordre

  Verify.evidence(dossier, page, 'mobile', "debord=#{debord} colonne_sous_le_titre=#{ordre}")
  page.current_window.resize_to(1280, 1024)
  page.accept_confirm("Supprimer « #{nom} » ?") { page.click_button 'Supprimer' }
  page.assert_text "« #{nom} » supprimé."
  Verify.evidence(dossier, page, 'supprimee', "reste_en_base=#{ActiveRecord::Base.uncached { Demarche.where(nom:).count }}")
ensure
  page.current_window.resize_to(1280, 1024)
  Demarche.where(slug:).destroy_all
end

def historique(page)
  dossier = 'admin-historique'
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  demarche = PaperTrail.request(whodunnit: 'Import Grist') { Demarche.create!(nom:) }
  ouvrir_fiche(page, nom)
  page.assert_selector 'aside.admin-panneau', text: /Créée par Import Grist le/
  Verify.evidence(dossier, page, 'creee', "colonne=#{page.find('aside.admin-panneau').text.lines.grep(/par/).first&.strip}")

  page.fill_in 'Nom', with: "#{nom} renommée"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} renommée » enregistré."
  page.assert_selector 'aside.admin-panneau', text: /Modifiée par #{Verify::ADMIN[:email]} le/
  auteurs = ActiveRecord::Base.uncached { demarche.versions.reload.map(&:whodunnit) }
  raise "auteurs #{auteurs}" unless auteurs == ['Import Grist', Admin.find_by(email: Verify::ADMIN[:email]).id.to_s]

  Verify.evidence(dossier, page, 'modifiee', "versions=#{auteurs}")
  page.click_link 'Historique'
  page.assert_current_path("/admin/historique/demarches/#{demarche.id}")
  titres = page.all('main section h2').map(&:text)
  raise "titres #{titres}" unless titres.size == 2 && titres.first.start_with?("Modification par #{Verify::ADMIN[:email]}") && titres.last.start_with?('Création par Import Grist')

  ligne = page.first('main section tbody tr').all('th, td').map(&:text)
  raise "ligne #{ligne}" unless ligne == ['Nom', nom, "#{nom} renommée"]

  Verify.evidence(dossier, page, 'page', "titres=#{titres} premiere_ligne=#{ligne}")
  page.current_window.resize_to(375, 800)
  debord = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')
  raise "375 px : débord #{debord}" if debord.positive?

  Verify.evidence(dossier, page, 'mobile', "debord=#{debord}")
  page.current_window.resize_to(1280, 1024)
  page.click_link 'Retour à la fiche'
  page.find_field('Nom', with: "#{nom} renommée")
  Verify.evidence(dossier, page, 'retour', "chemin=#{page.current_path}")
ensure
  page.current_window.resize_to(1280, 1024)
  ids = Demarche.where('nom LIKE ?', "#{nom}%").ids
  Demarche.where(id: ids).destroy_all
  PaperTrail::Version.where(item_type: 'Demarche', item_id: ids).delete_all
end

{ 'catalogue' => :catalogue, 'fiche' => :fiche, 'connexion' => :connexion, 'vocabulaires' => :vocabulaires,
  'cascade' => :cascade, 'saisies' => :saisies, 'contenu-html' => :contenu_html,
  'incoherences' => :incoherences, 'dates' => :dates, 'lecture-seule' => :lecture_seule,
  'formulaire-modifie' => :formulaire_modifie, 'libelles' => :libelles,
  'erreurs' => :erreurs, 'listes' => :listes, 'listes-lisibles' => :listes_lisibles, 'liste-filtrable' => :liste_filtrable,
  'homonymes' => :homonymes, 'pages-liees' => :pages_liees,
  'recommandations-demarche' => :recommandations_demarche, 'formulaire-solution' => :formulaire_solution,
  'saisie-solution' => :saisie_solution,
  'fournisseurs' => :fournisseurs, 'colonne' => :colonne, 'historique' => :historique }.each do |nom, fn|
  next if only && only != nom

  method(fn).call(page)
  puts "ok #{nom}"
rescue StandardError => e
  Verify.evidence(nom, page, 'echec')
  puts "ECHEC #{nom}: #{e.class} #{e.message}"
end
page.quit
