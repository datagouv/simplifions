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
  page.select 'usager', from: 'Categorie'
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
  page.assert_selector 'td', text: nom
  ligne = Vocabulaire.find_by!(nom:)
  Verify.evidence('admin-vocabulaires', page, 'cree', "id=#{ligne.id} nom=#{ligne.nom} categorie=#{ligne.categorie}")
  page.within(:xpath, "//tr[td[text()='#{nom}']]") { page.accept_confirm { page.click_button 'Supprimer' } }
  page.assert_text 'Supprimé.'
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
  page.assert_selector 'td', text: nom
  Verify.evidence('admin-supprimer-demarche', page, 'avant',
    "demarche=#{demarche.id} recommandations=#{Recommandation.where(demarche:).count} solution=#{solution.id}")
  page.within(:xpath, "//tr[td[text()='#{nom}']]") { page.accept_confirm { page.click_button 'Supprimer' } }
  page.assert_text 'Supprimé.'
  page.assert_no_selector 'td', text: nom
  ActiveRecord::Base.uncached do
    Verify.evidence('admin-supprimer-demarche', page, 'apres',
      "demarche_en_base=#{Demarche.where(nom:).count} recommandations=#{Recommandation.where(demarche:).count} " \
      "solution_en_base=#{Solution.where(id: solution.id).count}")
  end
  Verify.logout(page)
end

def saisies(page)
  Verify.login(page)
  solution = Solution.visibles.fiches.where.not(slug: nil).order(:id).find { |s| !s.privee? }
  site_avant = solution.site_internet
  page.visit("/admin/solutions/#{solution.id}/edit")
  page.fill_in 'Site internet', with: 'www.exemple-verif.fr'
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
  page.visit("/solutions/#{solution.slug}")
  page.assert_selector :link, 'Site de la solution', href: 'https://www.exemple-verif.fr'
  Verify.evidence('admin-saisies-controlees', page, 'url-completee',
    "solution=#{solution.id} saisi=www.exemple-verif.fr en_base=#{solution.reload.site_internet}")
  solution.update!(site_internet: site_avant)

  integration = Integration.en_production.order(:id).first
  page.visit("/admin/integrations/#{integration.id}/edit")
  options = page.find_field('Statut').all('option').map(&:value)
  raise "options #{options}" unless options == ['', *Integration::STATUTS]

  page.select Integration::STATUT_EN_PRODUCTION, from: 'Statut'
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
  Verify.evidence('admin-saisies-controlees', page, 'statut-liste',
    "integration=#{integration.id} options=#{options.size} en_base=#{integration.reload.statut}")

  organisation = solution.organisations.find_by!(public_ou_prive: 'Public')
  page.visit("/admin/organisations/#{organisation.id}/edit")
  page.assert_selector :radio_button, 'Public', checked: true, visible: :all
  Verify.evidence('admin-saisies-controlees', page, 'radios-public-prive')
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
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
  page.select integration.integratrice.nom, from: 'Integree'
  page.click_button 'Enregistrer'
  page.assert_text 'Une solution ne peut pas s’intégrer elle-même'
  Verify.evidence('admin-saisies-controlees', page, 'integration-elle-meme',
    "integration=#{integration.id} integratrice=#{integration.integratrice_id} integree_en_base=#{integration.reload.integree_id}")

  nom = "Vérif verify-map #{Verify.browser}"
  page.visit('/admin/vocabulaires/new')
  page.fill_in 'Nom', with: nom
  page.select 'usager', from: 'Categorie'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug doit être rempli'
  page.fill_in 'Slug', with: 'Vérif Accents'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'
  Verify.evidence('admin-saisies-controlees', page, 'vocabulaire-sans-slug', "en_base=#{Vocabulaire.where(nom:).count}")
  Verify.logout(page)
end

def dates(page)
  nom = "Vérif verify-map #{Verify.browser}"
  Verify.login(page)
  page.visit('/admin/demarches/new')
  page.assert_no_selector "[name='demarche[cree_le]'], [name='demarche[modifie_le]']"
  page.fill_in 'Nom', with: nom
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
  demarche = ActiveRecord::Base.uncached { Demarche.find_by!(nom:) }
  creation = demarche.cree_le
  raise "dates a la creation #{creation.inspect} #{demarche.modifie_le.inspect}" unless creation&.after?(1.minute.ago) && demarche.modifie_le

  Verify.evidence('admin-dates', page, 'cree', "demarche=#{demarche.id} cree_le=#{creation.iso8601(3)} modifie_le=#{demarche.modifie_le.iso8601(3)}")
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Nom', with: "#{nom} modifiée"
  page.click_button 'Enregistrer'
  page.assert_text 'Enregistré.'
  demarche.reload
  raise "modification non datee #{demarche.modifie_le.inspect}" unless demarche.modifie_le > creation && demarche.cree_le == creation

  Verify.evidence('admin-dates', page, 'modifie', "demarche=#{demarche.id} cree_le=#{demarche.cree_le.iso8601(3)} modifie_le=#{demarche.modifie_le.iso8601(3)}")
  page.within(:xpath, "//tr[td[text()='#{nom} modifiée']]") { page.accept_confirm { page.click_button 'Supprimer' } }
  page.assert_text 'Supprimé.'
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

{ 'catalogue' => :catalogue, 'fiche' => :fiche, 'connexion' => :connexion, 'vocabulaires' => :vocabulaires,
  'cascade' => :cascade, 'saisies' => :saisies, 'contenu-html' => :contenu_html,
  'incoherences' => :incoherences, 'dates' => :dates, 'lecture-seule' => :lecture_seule }.each do |nom, fn|
  next if only && only != nom

  method(fn).call(page)
  puts "ok #{nom}"
rescue StandardError => e
  Verify.evidence(nom, page, 'echec')
  puts "ECHEC #{nom}: #{e.class} #{e.message}"
end
page.quit
