require_relative '../harness'

DOSSIER = 'title-seo'.freeze

def onglet_public(page, chemin)
  page.visit(chemin)
  [page.title, page.find('h1').text, page.find('meta[property="og:title"]', visible: false)[:content]]
end

def title_seo_publie(page, etape, chemin, saisie)
  page.fill_in 'Title SEO', with: saisie
  Verify.evidence(DOSSIER, page, "#{etape}-saisie")
  page.click_button 'Publier'
  page.assert_text 'enregistré.'
  onglet, h1, partage = onglet_public(page, chemin)
  Verify.evidence(DOSSIER, page, etape, "onglet=#{onglet} h1=#{h1} og:title=#{partage}")
  page.visit('/admin')
  [onglet, h1, partage]
end

def titre_par_defaut(page, nom, slug)
  avant = onglet_public(page, "/demarches/#{slug}")
  raise "avant : #{avant}" unless avant.first == "Cas d'usage - #{nom} | Simplifions.data.gouv.fr"

  Verify.evidence(DOSSIER, page, 'demarche-avant', "onglet=#{avant.first}")
  page.visit('/admin')
  avant.first
end

def publier_sur_la_demarche(page, ctx, saisie)
  Verify.ouvrir_fiche(page, ctx[:nom])
  title_seo_publie(page, saisie.empty? ? 'demarche-videe' : 'demarche-publiee', "/demarches/#{ctx[:slug]}", saisie)
end

def sans_champ_sur_l_api(page, api)
  page.visit("/admin/solutions/#{api.id}/edit")
  page.assert_no_selector :field, 'Title SEO'
end

def preuve(page, ctx)
  titres = ActiveRecord::Base.uncached { [ctx[:demarche].reload.titre_seo, ctx[:solution].reload.titre_seo] }
  Verify.evidence(DOSSIER, page, 'api-sans-champ', "base=#{titres}")
  Verify.logout(page)
end

def creer_les_fiches(nom, slug)
  { nom:, slug:, demarche: Demarche.create!(nom:, slug:, visible: true),
    solution: Solution.create!(nom:, slug:, visible: true, categorie: 'brique_logicielle'),
    api: Solution.create!(nom: "#{nom} api", categorie: 'api') }
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  slug = "verif-verify-map-#{Verify.browser}"
  saisie = "Vérif title SEO #{Verify.browser}"
  attendu = [saisie, nom, saisie]
  Verify.login(page)
  ctx = creer_les_fiches(nom, slug)
  defaut = Verify.check('Default') { titre_par_defaut(page, nom, slug) }
  Verify.check('Démarche') do
    publie = publier_sur_la_demarche(page, ctx, saisie)
    raise "démarche : #{publie}, base #{ctx[:demarche].reload.titre_seo.inspect}" unless publie == attendu
  end
  Verify.check('Emptied') { publier_sur_la_demarche(page, ctx, '').then { raise "vidé : #{it}" unless it.first == defaut } }
  Verify.check('Solution') do
    page.visit("/admin/solutions/#{ctx[:solution].id}/edit")
    title_seo_publie(page, 'solution-publiee', "/solutions/#{slug}", saisie).then { raise "solution : #{it}" unless it == attendu }
  end
  Verify.check('API') { sans_champ_sur_l_api(page, ctx[:api]) }
  Verify.check('Proof') { preuve(page, ctx) }
ensure
  Demarche.where(slug:).destroy_all
  Solution.where(slug:).or(Solution.where(nom: "#{nom} api")).destroy_all
end
