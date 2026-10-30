require_relative '../harness'

DOSSIER = 'admin-saisies-controlees'.freeze
SLUG_REFUSE = 'Slug ne doit contenir que des minuscules sans accent, des chiffres et des tirets'.freeze

def url_completee(page, solution)
  page.visit("/admin/solutions/#{solution.id}/edit")
  page.fill_in 'Site internet', with: 'www.exemple-verif.fr'
  page.click_button 'Publier'
  page.assert_text "« #{solution.libelle_admin} » enregistré."
  page.visit("/solutions/#{solution.slug}")
  page.assert_selector :link, 'Site de la solution', href: 'https://www.exemple-verif.fr'
  Verify.evidence(DOSSIER, page, 'url-completee', "solution=#{solution.id} saisi=www.exemple-verif.fr en_base=#{solution.reload.site_internet}")
end

def options_du_statut(page)
  champ = page.find_field('Statut de l’intégration')
  champ.all('option').map(&:value).tap { |options| raise "options #{options}" unless options == ['', *Integration::STATUTS] }
end

def reselectionner_en_production(page)
  page.find_field('Statut de l’intégration').find('option[value=""]').select_option
  page.select Integration::STATUT_EN_PRODUCTION, from: 'Statut de l’intégration'
end

def statut_en_liste(page)
  integration = Integration.en_production.order(:id).first
  page.visit("/admin/integrations/#{integration.id}/edit")
  options = options_du_statut(page)
  reselectionner_en_production(page)
  page.click_button 'Enregistrer'
  page.assert_text "« #{integration.libelle} » enregistré."
  Verify.evidence(DOSSIER, page, 'statut-liste', "integration=#{integration.id} options=#{options.size} en_base=#{integration.reload.statut}")
end

def reenregistrer_public(page, organisation)
  page.visit("/admin/organisations/#{organisation.id}/edit")
  page.assert_selector :radio_button, 'Public', checked: true, visible: :all
  Verify.evidence(DOSSIER, page, 'radios-public-prive')
  page.fill_in 'organisation[nom]', with: organisation.nom
  page.click_button 'Enregistrer'
  page.assert_text "« #{organisation.nom} » enregistré."
end

def public_ou_prive(page, solution)
  organisation = solution.organisations.find_by!(public_ou_prive: 'Public')
  reenregistrer_public(page, organisation)
  page.visit("/solutions/#{solution.slug}")
  page.assert_text(/Solution publique \| #{Regexp.escape(organisation.nom)}/i)
  Verify.evidence(DOSSIER, page, 'solution-reste-publique',
    "organisation=#{organisation.id} en_base=#{organisation.reload.public_ou_prive} privee=#{solution.reload.privee?}")
end

def slug_refuse(page)
  demarche = Demarche.visibles.order(:id).first
  page.visit("/admin/demarches/#{demarche.id}/edit")
  page.fill_in 'Slug', with: 'Vérif avec espaces/et accents'
  page.click_button 'Publier'
  page.assert_text SLUG_REFUSE
  page.assert_selector :field, 'Slug', with: 'Vérif avec espaces/et accents'
  Verify.evidence(DOSSIER, page, 'slug-refuse', "demarche=#{demarche.id} en_base=#{demarche.reload.slug}")
  page_publique_intacte(page, demarche)
end

def page_publique_intacte(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  page.assert_selector 'h1', text: demarche.nom
  Verify.evidence(DOSSIER, page, 'page-publique', "path=#{page.current_path}")
end

def integrer_a_elle_meme(page, integration)
  page.visit("/admin/integrations/#{integration.id}/edit")
  page.select integration.integratrice.libelle_admin, from: 'API ou jeu de données'
  page.click_button 'Enregistrer'
  page.assert_text 'Une solution ne peut pas s’intégrer elle-même'
end

def integration_elle_meme(page)
  integration = Integration.order(:id).first!
  integree = integration.integree_id
  integrer_a_elle_meme(page, integration)
  ActiveRecord::Base.uncached { integration.reload }
  raise "intégrée changée en base : #{integration.integree_id}" unless integration.integree_id == integree

  Verify.evidence(DOSSIER, page, 'integration-elle-meme',
    "integration=#{integration.id} integratrice=#{integration.integratrice_id} integree_en_base=#{integration.integree_id}")
end

def vocabulaire_sans_slug(page, nom)
  page.visit('/admin/vocabulaires/new')
  page.fill_in 'Nom', with: nom
  page.select 'Usager', from: 'Catégorie'
  page.click_button 'Enregistrer'
  page.assert_text 'Slug doit être rempli'
  page.fill_in 'Slug', with: 'Vérif Accents'
  page.click_button 'Enregistrer'
  page.assert_text SLUG_REFUSE
  crees = ActiveRecord::Base.uncached { Vocabulaire.where(nom:).count }
  raise "#{crees} vocabulaire(s) créé(s)" unless crees.zero?

  Verify.evidence(DOSSIER, page, 'vocabulaire-sans-slug', "en_base=#{crees}")
end

def quitter(page)
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  solution = Solution.visibles.fiches.where.not(slug: nil).order(:id).find { |s| !s.privee? }
  site_avant = solution.site_internet
  Verify.login(page)

  Verify.check('URL') { url_completee(page, solution) }
  solution.update!(site_internet: site_avant)
  Verify.check('Statut') { statut_en_liste(page) }
  Verify.check('Public ou privé') { public_ou_prive(page, solution) }
  Verify.check('Slug') { slug_refuse(page) }
  Verify.check('Incohérences') do
    integration_elle_meme(page)
    vocabulaire_sans_slug(page, nom)
  end
  Verify.check('Proof') { quitter(page) }
ensure
  solution&.update!(site_internet: site_avant)
  Vocabulaire.where(nom:).destroy_all
end
