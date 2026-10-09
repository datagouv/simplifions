require_relative 'harness'

def rubrique(page, nom)
  lien = page.find("nav[aria-label='Menu de l’administration']").find_link(nom)
  chemin = URI(lien[:href]).path
  lien.click
  page.assert_current_path(chemin)
end

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
  rubrique(page, 'Vocabulaires')
  page.assert_selector 'h1', text: 'Vocabulaires'
  page.click_link 'Ajouter'
  page.fill_in 'Nom', with: nom
  page.fill_in 'Slug', with: "verif-verify-map-#{Verify.browser}"
  page.select 'Usager', from: 'Catégorie'
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  ligne = Vocabulaire.find_by!(nom:)
  page.assert_current_path("/admin/vocabulaires/#{ligne.id}")
  page.assert_selector 'h1', text: nom
  lecture = page.all('dt').map { |terme| "#{terme.text}=#{terme.find(:xpath, 'following-sibling::dd[1]').text}" }
  raise "lecture #{lecture}" unless lecture.first(2) == ['Slug=' + "verif-verify-map-#{Verify.browser}", 'Catégorie=Usager']
  fil = page.all('.fr-breadcrumb__list li', visible: :all).map { |etape| etape.text(:all).strip }
  raise "fil #{fil}" unless fil == ['Administration', 'Vocabulaires', nom]

  Verify.evidence('admin-vocabulaires', page, 'cree',
    "id=#{ligne.id} nom=#{ligne.nom} categorie=#{ligne.categorie} url=#{page.current_path} lecture=#{lecture.join(' | ')} fil=#{fil.join(' > ')} onglet=#{page.title}")
  page.click_link 'Modifier'
  page.fill_in 'Nom', with: "#{nom} modifié"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} modifié » enregistré."
  page.assert_selector 'h1', text: "#{nom} modifié"
  Verify.evidence('admin-vocabulaires', page, 'modifie',
    "url=#{page.current_path} nom_en_base=#{ActiveRecord::Base.uncached { ligne.reload.nom }} onglet=#{page.title}")
  page.click_link 'Modifier'
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » enregistré."
  rubrique(page, 'Vocabulaires')
  page.assert_no_selector :button, 'Supprimer'
  ouvrir_depuis_la_liste(page, nom)
  page.click_link 'Modifier'
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
  rubrique(page, 'Démarches')
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
  page.click_button 'Publier'
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
  page.click_button 'Publier'
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
  rubrique(page, 'Solutions')
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
  rubrique(page, 'Recommandations')
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
  rubrique(page, 'Organisations')
  raise 'pagination organisations' if page.has_css?('.fr-pagination', wait: 0)
  raise "organisations #{lignes_affichees(page).size} != #{Organisation.count}" unless lignes_affichees(page).size == Organisation.count

  organisation = Organisation.where.not(nom_long: [nil, '']).order(:id).first
  page.assert_selector 'tbody tr', text: "#{organisation.nom} #{organisation.nom_long}"
  Verify.evidence(dossier, page, 'organisations-une-page', "lignes=#{lignes_affichees(page).size} en_base=#{Organisation.count} nom_long=#{organisation.nom_long}")
  rubrique(page, 'Intégrations')
  integration = Integration.includes(:integratrice, :integree).order(:id).first
  attendu = [integration.id.to_s, integration.integratrice.libelle_admin, integration.integree.libelle_admin, integration.type_libelle, integration.statut.to_s]
  raise "entetes #{page.all('thead th').map(&:text)}" unless page.all('thead th').map(&:text) == ['Id', 'Solution', 'API ou jeu de données', 'Type d’intégration', 'Statut de l’intégration']
  raise "intégration #{lignes_affichees(page).first} != #{attendu}" unless lignes_affichees(page).first == attendu

  Verify.evidence(dossier, page, 'integrations-colonnes', "premiere=#{attendu.join(' | ')}")
  rubrique(page, 'Démarches')
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
  rubrique(page, 'Démarches')
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
  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_1)
  integrations = Integration.where(integree_id: api).includes(:integratrice, :integree).order(:id).to_a
  demarche.integrations = integrations.first(2)
  cible = integrations.last
  Verify.login(page)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  categories = page.all('fieldset fieldset > legend').map(&:text)
  raise "groupes de vocabulaires #{categories}" unless categories == ['Usager', 'Type de simplification', 'Catégorie de solution']

  aides = liens_d_aide(page.find('fieldset', text: 'Vocabulaires', match: :first)).size
  raise "#{aides} « ? » pour #{Vocabulaire.count} vocabulaires" unless aides == Vocabulaire.count

  onglet(page, 'Intégrations')
  groupe = page.find('fieldset', text: 'Filtrer les intégrations')
  coches = cases_affichees(groupe)
  raise "cases visibles sans filtre #{coches.size}" unless coches.size == 2 && coches.all?(&:checked?)

  compte = groupe.find('[aria-live=polite]').text
  raise "compte #{compte}" unless compte == "2 cochés sur #{integrations.size}"

  Verify.evidence(dossier, page, 'cochees-seules', "visibles=#{coches.size} compte=#{compte} en_base=#{demarche.integration_ids.size} vocabulaires=#{categories.join(' | ')}")
  page.execute_script("document.getElementById('onglet-integrations-panneau').focus()")
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
  rubrique(page, 'Démarches')
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

def lien_nomme(zone, nom) = zone.all('a').find { |lien| (lien['aria-label'] || lien.text(:all).strip) == nom } || raise("aucun lien nommé #{nom}")

def liens_d_aide(zone) = zone.all('a:has(.fr-icon-question-line)').map { |lien| lien.text(:all).strip }

def trois_colonnes(page, attendues = 3)
  mesures = page.evaluate_script(<<~JS)
    [...document.querySelectorAll('input[name="demarche[vocabulaire_ids][]"]:not([type=hidden])')].map((c) => {
      const element = c.closest('.fr-fieldset__element')
      const [libelle, aide] = [element.querySelector('label'), element.querySelector('a')].map((n) => n.getBoundingClientRect())
      return [Math.round(element.getBoundingClientRect().top), aide.left >= libelle.right && aide.top < libelle.bottom]
    })
  JS
  par_ligne = mesures.group_by(&:first).values.map(&:size).max
  raise "#{par_ligne} vocabulaires par ligne au lieu de #{attendues}" unless par_ligne == attendues
  raise '« ? » pas à côté du libellé' unless mesures.all?(&:last)

  "vocabulaires_par_ligne=#{par_ligne} aide_a_cote=#{mesures.count(&:last)}/#{mesures.size}"
end

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
  liens = liens_d_aide(groupe)
  raise "liens #{liens} pour #{demarche.types_acteurs.map(&:nom)}" unless liens.sort == demarche.types_acteurs.map { |t| "Fiche de #{t.nom} (nouvel onglet)" }.sort

  colonnes = trois_colonnes(page)
  Verify.evidence(dossier, page, 'referentiel-trois-colonnes', "liens=#{liens.join(' | ')} #{colonnes}")
  vocabulaire = Vocabulaire.order(:id).first
  [[groupe, acteur, "/admin/types_acteurs/#{acteur.id}"], [page, vocabulaire, "/admin/vocabulaires/#{vocabulaire.id}"]].each do |zone, ligne, chemin|
    fiche = page.window_opened_by { lien_nomme(zone, "Fiche de #{ligne.nom} (nouvel onglet)").click }
    h1 = page.within_window(fiche) do
      page.assert_current_path(chemin)
      page.assert_selector :link, 'Modifier'
      page.find('h1').text
    end
    fiche.close
    raise 'le formulaire a été quitté' unless page.current_path == "/admin/demarches/#{demarche.id}/edit"

    Verify.evidence(dossier, page, "fiche-#{ligne.model_name.element}", "ouvert=#{chemin} h1=#{h1} formulaire=#{page.current_path}")
  end

  recommandation = Recommandation.first
  page.visit("/admin/recommandations/#{recommandation.id}/edit")
  lien_nomme(page, "Voir la fiche #{recommandation.solution.libelle_admin}").click
  page.assert_current_path("/admin/solutions/#{recommandation.solution_id}/edit")
  Verify.evidence(dossier, page, 'recommandation-vers-solution', "url=#{page.current_path} h1=#{page.find('h1').text}")
  page.current_window.resize_to(375, 1024)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.evidence(dossier, page, 'referentiel-375', trois_colonnes(page, 1))
  page.current_window.resize_to(320, 1024)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.evidence(dossier, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  groupe = page.find('fieldset', text: 'Filtrer les fournisseurs de services')
  groupe.fill_in 'Filtrer les fournisseurs de services', with: 'fiche de'
  filtre = cases_affichees(groupe).size
  raise "le filtre trouve le texte du lien (#{filtre})" unless filtre.zero?

  Verify.evidence(dossier, page, 'filtre-ignore-le-lien', "saisie=fiche de cases_affichees=#{filtre}")
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
  onglet(page, 'Recommandations')
  lignes = page.find('table[aria-labelledby=onglet-recommandations]').all('tbody tr').size
  raise "#{lignes} lignes pour #{avant} recommandations et la ligne vide" unless lignes == avant + 1

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
  onglet(page, 'Recommandations')
  derniere = page.find("tr#recommandation_#{creee.id}").all('select, input').map(&:value)
  raise 'nouvelle recommandation absente de la démarche' unless derniere.first == solution.id.to_s

  Verify.evidence(dossier, page, 'retour-demarche', "ligne=#{derniere.join(' | ')}")
  page.click_link "Modifier la recommandation #{solution.libelle_admin}"
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

def onglet(page, libelle)
  page.find('[role=tab]', text: /\A#{libelle}/).click
  page.assert_selector '[role=tab][aria-selected=true]', text: /\A#{libelle}/
end

def elements_lies(page)
  onglet(page, 'Intégrations')
  lies = page.all('#onglet-integrations-panneau h2').to_h { |titre| [titre.text, titre.find(:xpath, 'following-sibling::*[1]').all('a').map(&:text)] }
  onglet(page, 'Recommandée dans')
  lies.merge('Recommandée dans' => page.find('#onglet-recommandee-dans-panneau').all('a').map(&:text)).reject { |_, liens| liens.empty? }
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
  attendu = { 'Ce qu’elle intègre' => [api.libelle_admin], 'Recommandée dans' => [demarche.nom] }
  raise "legende=#{legende.tag_name}/#{legende[:type]} aide=#{aide} lies=#{lies}" unless
    legende[:type] == 'text' && aide == 'L’image sera retirée à l’enregistrement.' && lies == attendu

  Verify.evidence(dossier, page, 'fiche', "legende=#{legende.tag_name}[type=#{legende[:type]}] aide_retirer=#{aide} lies=#{lies}")
  onglet(page, 'Intégrations')
  page.find('#onglet-integrations-panneau').click_link api.libelle_admin
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
  rubrique(page, 'Fournisseurs de services')
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
  rubrique(page, 'Fournisseurs de services')
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

def barre(page, nom)
  page.all("nav[aria-label='#{nom}'] .fr-nav__link", visible: :all).map { |lien| [lien.text(:all).strip, lien['aria-current']] }
end

def rubrique_en_cours(page) = barre(page, 'Menu de l’administration').select(&:last)

RUBRIQUES_ADMIN = ['Démarches', 'Solutions', 'Recommandations', 'Intégrations', 'Organisations',
                   'Fournisseurs de services', 'Vocabulaires'].freeze

def navigation(page)
  dossier = 'admin-navigation'
  Verify.login(page)
  page.visit('/admin')
  rubriques = barre(page, 'Menu de l’administration').map(&:first)
  raise "rubriques #{rubriques}" unless rubriques == RUBRIQUES_ADMIN && rubrique_en_cours(page).empty?
  raise 'barre publique sous /admin' unless barre(page, 'Menu principal').empty?

  Verify.evidence(dossier, page, 'tableau-de-bord', "rubriques=#{rubriques.size} en_cours=#{rubrique_en_cours(page)}")
  rubrique(page, 'Solutions')
  page.assert_current_path('/admin/solutions')
  raise "en cours #{rubrique_en_cours(page)}" unless rubrique_en_cours(page) == [%w[Solutions page]]

  solution = Solution.first
  page.visit("/admin/solutions/#{solution.id}/edit")
  raise "fiche : en cours #{rubrique_en_cours(page)}" unless rubrique_en_cours(page) == [%w[Solutions true]]

  Verify.evidence(dossier, page, 'fiche-solution', "solution=#{solution.id} en_cours=#{rubrique_en_cours(page)}")
  page.visit("/admin/historique/solutions/#{solution.id}")
  raise "historique : en cours #{rubrique_en_cours(page)}" unless rubrique_en_cours(page) == [%w[Solutions true]]

  Verify.evidence(dossier, page, 'historique', "chemin=#{page.current_path} en_cours=#{rubrique_en_cours(page)}")
  page.current_window.resize_to(375, 800)
  page.visit('/admin')
  page.click_button 'Menu'
  page.within('#modal-menu') do
    visibles = page.all('.fr-nav__link').map(&:text)
    raise "mobile #{visibles}" unless visibles == RUBRIQUES_ADMIN

    Verify.evidence(dossier, page, 'menu-375', "rubriques=#{visibles.size}")
    page.click_link 'Vocabulaires'
  end
  page.assert_current_path('/admin/vocabulaires')
  debord = page.evaluate_script('document.documentElement.scrollWidth - document.documentElement.clientWidth')
  raise "375 px : débord #{debord}" if debord.positive? || rubrique_en_cours(page) != [%w[Vocabulaires page]]

  Verify.evidence(dossier, page, 'vocabulaires-375', "en_cours=#{rubrique_en_cours(page)} debord=#{debord}")
  page.current_window.resize_to(1280, 1024)
  page.visit('/')
  publique = barre(page, 'Menu principal').map(&:first)
  raise "public #{publique}" unless publique == ['Accueil', "Cas d'usages", 'Articles', 'À propos'] && barre(page, 'Menu de l’administration').empty?

  Verify.evidence(dossier, page, 'site-public', "barre=#{publique}")
ensure
  page.current_window.resize_to(1280, 1024)
end

def cases_de(page, groupe) = page.all("input[type=checkbox][name$='[#{groupe}][]']", visible: :all)

def hors_regle(page, groupe) = page.all("input[type=checkbox][name$='[#{groupe}][]'] + label", visible: :all).count { |l| l.text(:all).end_with?('(hors règle)') }

def integrations_de_l_api(page)
  dossier = 'admin-integrations-de-l-api'
  Verify.login(page)
  demarche = Demarche.find(1)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  cases = cases_de(page, 'integration_ids').size
  attendu = demarche.integrations_proposees.count
  marquees = hors_regle(page, 'integration_ids')
  hors = demarche.integrations.where.not(id: demarche.integrations_autorisees).count
  raise "démarche 1 : #{cases} cases pour #{attendu} proposées" unless cases == attendu && cases < Integration.count
  raise "démarche 1 : #{marquees} marquées hors règle pour #{hors}" unless marquees == hors

  Verify.evidence(dossier, page, 'demarche-1', "cases=#{cases} avant=#{Integration.count} hors_regle=#{marquees} cochees=#{demarche.integrations.count}")
  integration = Integration.joins(:demarches).where.not(
    'EXISTS (SELECT 1 FROM recommandations r WHERE r.demarche_id = demarches.id AND r.solution_id = integrations.integree_id)'
  ).first!
  page.visit("/admin/integrations/#{integration.id}/edit")
  cases = cases_de(page, 'demarche_ids').size
  raise "intégration : #{cases} cases pour #{integration.demarches_proposees.count}" unless cases == integration.demarches_proposees.count
  raise 'intégration : aucune démarche marquée hors règle' unless hors_regle(page, 'demarche_ids').positive?

  Verify.evidence(dossier, page, 'integration', "integration=#{integration.id} cases=#{cases} avant=#{Demarche.count} hors_regle=#{hors_regle(page, 'demarche_ids')}")
  avant = integration.demarche_ids.sort
  intrus = Demarche.where.not(id: integration.demarches_proposees).first!
  page.execute_script(
    "const c = document.createElement('input'); c.type = 'hidden'; c.name = 'integration[demarche_ids][]'; c.value = arguments[0]; document.getElementById('formulaire-fiche').append(c); c.dispatchEvent(new Event('change', { bubbles: true }))", intrus.id
  )
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-alert--error', text: "La démarche « #{intrus.nom} » ne recommande pas l’API ou le jeu de données intégré"
  ActiveRecord::Base.uncached do
    apres = Integration.find(integration.id).demarche_ids.sort
    raise "refus : base modifiée #{avant} → #{apres}" unless apres == avant

    Verify.evidence(dossier, page, 'refus-serveur', "intrus=#{intrus.id} en_base_avant=#{avant.size} en_base_apres=#{apres.size}")
  end
  page.visit('/admin/integrations/new')
  raise 'nouvelle intégration : cases de démarches' unless cases_de(page, 'demarche_ids').empty?

  page.assert_text 'Démarches : à cocher une fois l’API ou le jeu de données enregistré'
  Verify.evidence(dossier, page, 'nouvelle-integration', 'cases=0 message=affiché')
  page.visit('/admin')
  Verify.logout(page)
end

def titre_public(page, slug)
  page.visit("/demarches/#{slug}")
  page.find('h1').text.tap { page.visit('/admin') }
end

def brouillon(page)
  dossier = 'admin-brouillon'
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Verify.login(page)
  demarche = Demarche.create!(nom:, slug:, visible: true)
  ouvrir_fiche(page, nom)
  page.fill_in 'Nom', with: "#{nom} brouillon"
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} » : brouillon enregistré, non publié."
  page.assert_selector 'aside.admin-panneau', text: /Brouillon non publié/i
  page.assert_selector 'aside.admin-panneau', text: %r{Brouillon du \d\d/\d\d/\d{4} à \d\d:\d\d}
  base = ActiveRecord::Base.uncached { demarche.reload.slice(:nom, :visible) }
  raise "brouillon : base #{base}" unless base == { 'nom' => nom, 'visible' => true }

  Verify.evidence(dossier, page, 'brouillon', "base=#{base} brouillon=#{demarche.brouillon&.slice('nom')}")
  titre = titre_public(page, slug)
  raise "page publique #{titre}" unless titre.include?(nom) && !titre.include?('brouillon')

  Verify.evidence(dossier, page, 'page-publique-inchangee', "h1=#{titre}")
  rubrique(page, 'Démarches')
  ouvrir_depuis_la_liste(page, nom)
  page.find_field('Nom', with: "#{nom} brouillon")
  page.click_button 'Publier'
  page.assert_text "« #{nom} brouillon » enregistré."
  page.assert_no_selector 'aside.admin-panneau', text: /Brouillon/i
  titre = titre_public(page, slug)
  raise "publication : page publique #{titre}" unless titre.include?("#{nom} brouillon")

  Verify.evidence(dossier, page, 'page-publique-publiee', "h1=#{titre} brouillon_en_base=#{ActiveRecord::Base.uncached { demarche.reload.brouillon.inspect }}")
  ouvrir_fiche(page, "#{nom} brouillon")
  page.fill_in 'Nom', with: "#{nom} à jeter"
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: /Brouillon non publié/i
  page.accept_confirm("Abandonner le brouillon de « #{nom} brouillon » ? Les modifications non publiées seront perdues.") { page.click_button 'Abandonner le brouillon' }
  page.assert_text "Brouillon de « #{nom} brouillon » abandonné."
  page.find_field('Nom', with: "#{nom} brouillon")
  base = ActiveRecord::Base.uncached { demarche.reload.slice(:nom, :brouillon) }
  raise "abandon : base #{base}" unless base == { 'nom' => "#{nom} brouillon", 'brouillon' => nil }

  Verify.evidence(dossier, page, 'abandonne', "base=#{base}")
  brouillon_image(page, dossier, nom, slug)
  brouillon_recommandations(page, dossier, nom, slug)
  page.visit('/admin')
  Verify.logout(page)
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).or(Solution.where(nom: ["#{nom} a", "#{nom} b"])).destroy_all
end

def cartes_publiques(page, slug)
  page.visit("/demarches/#{slug}")
  page.all('.reco-card').map { it.text.squish }.tap { page.visit('/admin') }
end

def brouillon_recommandations(page, dossier, nom, slug)
  demarche = Demarche.find_by!(slug:)
  modifiee, ajoutee = %w[a b].map { Solution.create!(nom: "#{nom} #{it}", categorie: 'api') }
  reco = Recommandation.create!(demarche:, solution: modifiee, niveau: :niveau_2, donnees_utiles: 'Avant', visible: true)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  onglet(page, 'Recommandations')
  page.click_link modifiee.libelle_admin
  page.fill_in 'Données utiles disponibles', with: 'Après'
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: /Brouillon — sera publiée avec la démarche/i
  Verify.evidence(dossier, page, 'reco-modifiee', "base=#{ActiveRecord::Base.uncached { reco.reload.slice(:donnees_utiles, :visible) }} brouillon=#{reco.brouillon&.slice('donnees_utiles')}")
  page.visit("/admin/recommandations/new?demarche_id=#{demarche.id}")
  page.select ajoutee.libelle_admin, from: 'Solution (obligatoire)'
  page.select 'Solution recommandée', from: 'Type de recommandation'
  page.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} → #{ajoutee.libelle_admin} » : brouillon enregistré, non publié."
  page.assert_selector 'aside.admin-panneau', text: /Masquée.*Brouillon — sera publiée avec la démarche/im
  nouvelle = ActiveRecord::Base.uncached { demarche.recommandations.find_by!(solution: ajoutee) }
  Verify.evidence(dossier, page, 'reco-ajoutee', "visible=#{nouvelle.visible} brouillon=#{nouvelle.brouillon.slice('visible')}")
  cartes = cartes_publiques(page, slug)
  raise "page publique avant : #{cartes}" unless cartes.size == 1 && cartes.first.include?('Avant')

  Verify.evidence(dossier, page, 'page-publique-avant', "cartes=#{cartes.size}")
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.assert_selector 'aside.admin-panneau', text: '2 recommandations en brouillon'
  Verify.evidence(dossier, page, 'demarche-2-en-brouillon', "en_base=#{demarche.recommandations_en_brouillon.count}")
  page.click_button 'Publier'
  page.assert_text "« #{demarche.nom} » enregistré."
  page.assert_no_selector 'aside.admin-panneau', text: 'en brouillon'
  cartes = cartes_publiques(page, slug)
  raise "page publique après : #{cartes}" unless cartes.size == 2 && cartes.join.include?('Après')

  Verify.evidence(dossier, page, 'page-publique-apres', "cartes=#{cartes.size} brouillons=#{ActiveRecord::Base.uncached { demarche.recommandations_en_brouillon.count }}")
end

def brouillon_image(page, dossier, nom, slug)
  solution = Solution.create!(nom:, slug:, visible: true)
  rubrique(page, 'Solutions')
  ouvrir_depuis_la_liste(page, nom)
  page.attach_file('solution_image', Rails.root.join('app/assets/images/solutions/data-subvention.png').to_s)
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: /Brouillon non publié/i
  page.assert_selector '.fr-upload-group img[src*="data-subvention.png"]'
  attachee = ActiveRecord::Base.uncached { Solution.find(solution.id).image.attached? }
  raise 'image en brouillon déjà attachée' if attachee

  Verify.evidence(dossier, page, 'image-en-brouillon', "image_attachee=#{attachee} brouillon_image=#{solution.reload.brouillon&.key?('image')}")
  page.click_button 'Publier'
  page.assert_text "« #{nom} » enregistré."
  fichier = ActiveRecord::Base.uncached { Solution.find(solution.id).image.filename.to_s }
  raise "publication : image #{fichier}" unless fichier == 'data-subvention.png'

  Verify.evidence(dossier, page, 'image-publiee', "image=#{fichier} brouillon=#{solution.reload.brouillon.inspect}")
end

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

def previsualisation(page)
  dossier = 'admin-previsualisation'
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  Verify.login(page)
  demarche = Demarche.create!(nom:, slug:, visible: true)
  ouvrir_fiche(page, nom)
  page.assert_no_selector :link, 'Prévisualiser'
  page.fill_in 'Nom', with: "#{nom} brouillon"
  page.click_button 'Enregistrer'
  previsualiser(page) do
    page.assert_selector 'h1', text: "#{nom} brouillon"
    page.assert_selector '.fr-notice', text: 'Prévisualisation, non publiée.'
    Verify.evidence(dossier, page, 'demarche', "h1=#{page.find('h1').text} titre=#{page.title} bandeau=#{page.find('.fr-notice').text.squish}")
    largeurs = previsualisation_lisible(page)
    Verify.evidence(dossier, page, 'demarche-640px', "scrollWidth/clientWidth=#{largeurs}")
  end
  titre = titre_public(page, slug)
  base = ActiveRecord::Base.uncached { demarche.reload.nom }
  raise "page publique #{titre} / base #{base}" unless titre == nom && base == nom

  Verify.evidence(dossier, page, 'page-publique-inchangee', "h1=#{titre} base=#{base} bandeau=#{page.has_css?('.fr-notice', wait: 0)}")
  solution = Solution.create!(nom:, slug:, visible: true)
  rubrique(page, 'Solutions')
  ouvrir_depuis_la_liste(page, nom)
  page.attach_file('solution_image', Rails.root.join('app/assets/images/solutions/data-subvention.png').to_s)
  page.click_button 'Enregistrer'
  previsualiser(page) do
    page.assert_selector '.fr-content-media img[src*="data-subvention.png"]'
    attachee = ActiveRecord::Base.uncached { Solution.find(solution.id).image.attached? }
    raise 'image attachée par la prévisualisation' if attachee

    Verify.evidence(dossier, page, 'solution-image', "image_du_brouillon=affichee image_en_base=#{attachee}")
  end
  page.visit('/admin')
  Verify.logout(page)
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).destroy_all
end

def image_refusee(page)
  dossier = 'admin-image-refusee'
  nom = "Vérif verify-map #{Verify.browser}"
  faux_png = Verify::ROOT.join('pdf-nomme.png').tap { it.dirname.mkpath }.tap { it.binwrite("%PDF-1.4\n") }
  Verify.login(page)
  solutions = [Solution.create!(nom: "#{nom} masquée"), Solution.create!(nom:, slug: "verif-verify-map-#{Verify.browser}", visible: true)]
  solutions.each { image_refusee_sur(page, dossier, it, faux_png) }
  page.attach_file('solution_image', Rails.root.join('app/assets/images/solutions/data-subvention.png').to_s)
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: /Brouillon non publié/i
  Verify.evidence(dossier, page, 'png-accepte', "brouillon_image=#{ActiveRecord::Base.uncached { solutions.last.reload.brouillon.to_h.key?('image') }}")
  page.visit('/admin')
  Verify.logout(page)
ensure
  Solution.where(nom: ["#{nom} masquée", nom, "#{nom} masquée renommée", "#{nom} renommée"]).destroy_all
end

def image_refusee_sur(page, dossier, solution, fichier)
  blobs = ActiveStorage::Blob.count
  page.visit('/admin/solutions')
  ouvrir_depuis_la_liste(page, solution.nom)
  page.fill_in 'Nom', with: "#{solution.nom} renommée"
  page.attach_file('solution_image', fichier.to_s)
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-upload-group', text: 'doit être une image png, jpg ou webp'
  page.find_field('Nom', with: "#{solution.nom} renommée")
  base = ActiveRecord::Base.uncached { Solution.find(solution.id).then { [it.nom, it.image.attached?, it.brouillon, ActiveStorage::Blob.count - blobs] } }
  raise "refus #{solution.nom} : base #{base}" unless base == [solution.nom, false, nil, 0]

  Verify.evidence(dossier, page, "refus-#{solution.visible? ? 'publiee' : 'masquee'}", "nom,image,brouillon,blobs_crees=#{base}")
end

def hauteur(page) = page.evaluate_script('document.documentElement.scrollHeight')

def onglet_retenu(page) = page.find('input[name=onglet]', visible: false).value

def onglets(page)
  dossier = 'admin-onglets'
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  page.visit('/admin/demarches/1/edit')
  libelles = page.all('[role=tab]').map(&:text)
  hauteurs = libelles.to_h { |libelle| onglet(page, libelle.split(' (').first).then { [libelle, hauteur(page)] } }
  raise "onglets #{libelles}" unless libelles.map { it.split(' (').first } == %w[Fiche Intégrations Recommandations Historique]

  Verify.evidence(dossier, page, 'hauteurs-demarche-1', "hauteurs=#{hauteurs} recos_en_base=#{Demarche.find(1).recommandations.count}")
  onglet(page, 'Fiche')
  page.find('[role=tab][aria-selected=true]').send_keys(:right)
  page.assert_selector '[role=tab][aria-selected=true]', text: /\AIntégrations/
  raise "flèche : onglet retenu #{onglet_retenu(page)}" unless onglet_retenu(page) == 'integrations'

  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_1)
  cible = Integration.where(integree_id: api).order(:id).first
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Nom', with: "#{nom} modifiée"
  onglet(page, 'Intégrations')
  groupe = page.find('fieldset', text: 'Filtrer les intégrations')
  groupe.fill_in 'Filtrer les intégrations', with: I18n.transliterate(cible.libelle).scan(/[[:alnum:]]+/).join(' ')
  groupe.find("label[for=demarche_integration_ids_#{cible.id}]").click
  raise 'case cible non cochée' unless groupe.find("#demarche_integration_ids_#{cible.id}", visible: :all).checked?
  page.click_button 'Enregistrer'
  page.assert_text "« #{nom} modifiée » enregistré."
  page.assert_current_path(/onglet=integrations/, url: true)
  page.assert_selector '[role=tab][aria-selected=true]', text: 'Intégrations (1)'
  base = ActiveRecord::Base.uncached { Demarche.find(demarche.id).then { [it.nom, it.integration_ids] } }
  raise "enregistrement : base #{base}" unless base == ["#{nom} modifiée", [cible.id]]

  Verify.evidence(dossier, page, 'enregistre-depuis-integrations', "url=#{page.current_url.split('/admin').last} base=#{base}")
  onglet(page, 'Fiche')
  page.fill_in 'Nom', with: ''
  onglet(page, 'Historique')
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-alert--error', text: 'Nom doit être rempli'
  page.assert_selector '[role=tab][aria-selected=true]', text: 'Fiche'
  page.assert_selector '#demarche_nom', visible: true
  Verify.evidence(dossier, page, 'erreur-ouvre-fiche', "onglet_ouvert=Fiche nom_en_base=#{ActiveRecord::Base.uncached { Demarche.find(demarche.id).nom }}")
  page.current_window.resize_to(375, 812)
  page.visit("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
  page.assert_selector '[role=tab][aria-selected=true]', text: /\ARecommandations/
  Verify.evidence(dossier, page, 'etroit-375', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
  page.visit('/admin')
  Verify.logout(page)
ensure
  Demarche.where(nom: [nom, "#{nom} modifiée"]).destroy_all
end

def enregistrer_desactive?(page) = page.find('button[data-enregistrer]', visible: :all).disabled?

def focus_sur(page) = page.evaluate_script('document.activeElement.id')

def recommandations_en_ligne(page)
  dossier = 'admin-recommandations-en-ligne'
  demarche = Demarche.visibles.where.not(slug: [nil, '']).max_by { |ligne| ligne.recommandations.count }
  reco = demarche.recommandations.visibles.par_niveau_et_ordre.first
  nom = "la recommandation #{reco.solution.libelle_admin}"
  solution = Solution.where(categorie: 'api').where.not(id: demarche.recommandations.select(:solution_id)).reject(&:privee?).first
  avant = demarche.recommandations.count
  publique = -> { page.visit("/demarches/#{demarche.slug}") || page.all('.reco-card').map(&:text) }
  cartes = publique.call
  Verify.login(page)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  onglet(page, 'Recommandations')
  page.find_field("Ordre de #{nom}").fill_in(with: '77')
  raise 'la ligne a marqué la fiche' unless enregistrer_desactive?(page)

  page.click_button "Enregistrer #{nom}"
  page.assert_selector '#message-recommandations .fr-valid-text', text: 'brouillon enregistré'
  page.find("tr#recommandation_#{reco.id}").assert_selector '.fr-badge--new', text: /brouillon/i
  ActiveRecord::Base.uncached do
    Verify.evidence(dossier, page, 'ligne-modifiee', "focus=#{focus_sur(page)} fiche_grisee=#{enregistrer_desactive?(page)} " \
      "ordre_en_base=#{reco.reload.ordre} ordre_du_brouillon=#{reco.brouillon&.dig('ordre')}")
  end

  onglet(page, 'Fiche')
  page.fill_in 'Description courte', with: "#{demarche.description_courte} "
  onglet(page, 'Recommandations')
  page.find_field("Ordre de #{nom}").fill_in(with: '78')
  page.click_button "Enregistrer #{nom}"
  page.assert_selector '#message-recommandations .fr-valid-text'
  raise 'la fiche modifiée a été oubliée' if enregistrer_desactive?(page)

  Verify.evidence(dossier, page, 'fiche-modifiee-garde', "confirmation=aucune fiche_grisee=#{enregistrer_desactive?(page)}")

  page.select 'Solution recommandée', from: 'Type de recommandation de la nouvelle recommandation (obligatoire)'
  page.click_button 'Ajouter la nouvelle recommandation'
  erreur = page.find('#erreurs_recommandation', text: 'Choisissez une solution')
  Verify.evidence(dossier, page, 'erreur-ligne', "erreur=#{erreur.text} focus=#{focus_sur(page)} " \
    "decrit_par=#{page.find('#enregistrer_recommandation')['aria-describedby']}")

  page.select solution.libelle_admin, from: 'Solution de la nouvelle recommandation (obligatoire)'
  page.find_field('Ordre de la nouvelle recommandation').fill_in(with: '99')
  page.click_button 'Ajouter la nouvelle recommandation'
  page.assert_selector '#message-recommandations .fr-valid-text', text: solution.libelle_admin
  creee = ActiveRecord::Base.uncached { demarche.recommandations.find_by!(solution:) }
  page.assert_selector "tr#recommandation_#{creee.id}"
  vide = page.find('tr#new_recommandation select[name="recommandation[solution_id]"]').value
  Verify.evidence(dossier, page, 'ajoutee', "lignes=#{page.all('tbody tr').size} en_base=#{ActiveRecord::Base.uncached { demarche.recommandations.count }} " \
    "avant=#{avant} visible=#{creee.visible} ligne_vide=#{vide.inspect} focus=#{focus_sur(page)}")

  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_link 'Annuler' }
  page.assert_selector 'h1', text: 'Démarches'
  apres = publique.call
  Verify.evidence(dossier, page, 'page-publique', "inchangee=#{apres == cartes} cartes=#{apres.size}")
  page.current_window.resize_to(375, 812)
  page.visit("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
  Verify.evidence(dossier, page, 'etroit-375', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)

  page.click_link "Modifier #{nom}"
  page.accept_confirm { page.click_button 'Abandonner le brouillon' }
  page.assert_text 'abandonné'
  page.visit("/admin/recommandations/#{creee.id}/edit")
  page.accept_confirm { page.click_button 'Supprimer' }
  page.assert_current_path('/admin/recommandations')
  ActiveRecord::Base.uncached do
    Verify.evidence(dossier, page, 'defait', "en_base=#{demarche.recommandations.count} avant=#{avant} brouillon=#{reco.reload.brouillon.inspect}")
  end
  Verify.logout(page)
ensure
  ActiveRecord::Base.uncached do
    demarche&.recommandations&.where(ordre: 99, grist_id: nil, solution:)&.destroy_all
    reco&.reload&.abandonner_brouillon! if reco&.reload&.brouillon?
  end
end

def contact(page)
  demarche = Demarche.visibles.order(:id).first
  page.visit("/demarches/#{demarche.slug}")
  page.click_link "proposer une modification du contenu de ce cas d'usage"
  page.assert_current_path("/contact/modifier-cas-usage?demarche=#{demarche.slug}")
  objet = page.find_field('Objet du message', readonly: true).value
  raise "objet sans la fiche : #{objet}" unless objet.end_with?(" : #{demarche.nom}")

  mailto = URI.decode_www_form_component(page.find_link("Écrire à l'équipe")[:href])
  raise "mailto sans la fiche : #{mailto}" unless mailto.include?("Fiche concernée : #{demarche.nom}")

  page.driver.browser.add_permission('clipboard-write', 'granted') if Verify.browser == 'chrome'
  page.click_button "Copier l'objet du message"
  page.assert_selector '[data-copier-target=statut]', text: 'Objet du message copié.', visible: :all
  Verify.evidence('contact', page, 'fiche-citee', "slug=#{demarche.slug} objet=#{objet} copie=ok")
  page.click_link 'Retour'
  page.assert_current_path('/contact/contenu')
  page.assert_selector 'h3', text: "Cas d'usages"
  page.click_link 'Retour'
  page.assert_current_path('/contact')
  page.click_link "J'ai une question sur ma propre démarche administrative"
  page.assert_text 'Nous ne sommes pas en mesure de vous aider à ce sujet.'
  raise 'adresse donnée sans contact' if page.has_link?("Écrire à l'équipe", wait: 0)

  Verify.evidence('contact', page, 'reponse-sans-adresse', "path=#{page.current_path} mailto=0")
end

{ 'catalogue' => :catalogue, 'fiche' => :fiche, 'connexion' => :connexion, 'vocabulaires' => :vocabulaires,
  'cascade' => :cascade, 'saisies' => :saisies, 'contenu-html' => :contenu_html,
  'incoherences' => :incoherences, 'dates' => :dates, 'lecture-seule' => :lecture_seule,
  'formulaire-modifie' => :formulaire_modifie, 'libelles' => :libelles,
  'erreurs' => :erreurs, 'listes' => :listes, 'listes-lisibles' => :listes_lisibles, 'liste-filtrable' => :liste_filtrable,
  'homonymes' => :homonymes, 'pages-liees' => :pages_liees,
  'recommandations-demarche' => :recommandations_demarche, 'formulaire-solution' => :formulaire_solution,
  'saisie-solution' => :saisie_solution,
  'fournisseurs' => :fournisseurs, 'colonne' => :colonne, 'historique' => :historique,
  'navigation' => :navigation, 'integrations-de-l-api' => :integrations_de_l_api, 'brouillon' => :brouillon,
  'previsualisation' => :previsualisation, 'image-refusee' => :image_refusee, 'onglets' => :onglets,
  'recommandations-en-ligne' => :recommandations_en_ligne,
  'contact' => :contact }.each do |nom, fn|
  next if only && only != nom

  method(fn).call(page)
  puts "ok #{nom}"
rescue StandardError => e
  Verify.evidence(nom, page, 'echec')
  puts "ECHEC #{nom}: #{e.class} #{e.message}"
end
page.quit
