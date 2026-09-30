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
  page.click_button 'Se déconnecter'
end

Verify.ensure_admin
{ 'catalogue' => :catalogue, 'fiche' => :fiche, 'connexion' => :connexion, 'vocabulaires' => :vocabulaires }.each do |nom, fn|
  next if only && only != nom

  method(fn).call(page)
  puts "ok #{nom}"
rescue StandardError => e
  Verify.evidence(nom, page, 'echec')
  puts "ECHEC #{nom}: #{e.class} #{e.message}"
end
page.quit
