require_relative '../harness'

DOSSIER = 'plan-du-site'.freeze

def feuilles_du_plan(page, entree)
  page.find('main li', text: entree, match: :first).all(':scope > ul a').map(&:text)
end

def attendus
  { "Cas d'usages" => Demarche.visibles.order(:nom).map { |demarche| demarche.nom.squish },
    'Solutions' => Solution.visibles.fiches.order(:nom).map { |solution| solution.nom.squish },
    'Articles' => Article.all.map(&:h1).sort }
end

def ouvrir(page)
  page.visit('/')
  page.within('footer') { page.click_link 'Plan du site' }
  page.assert_current_path('/sitemap')
end

def feuilles(page)
  attendus.each do |entree, noms|
    lus = feuilles_du_plan(page, entree)
    raise "#{entree} : #{lus.zip(noms).reject { |lu, nom| lu == nom }.first(3)}" unless lus == noms
  end
  attendus.map { |entree, noms| "#{entree}=#{noms.size}" }.join(' ')
end

def a_propos(page, comptes)
  apropos = feuilles_du_plan(page, 'À propos')
  raise "À propos #{apropos}" unless apropos.size == 3 && apropos.last == 'Guide pour la simplification'

  Verify.evidence(DOSSIER, page, 'bureau', "#{comptes} À propos=#{apropos}")
end

def mobile(page)
  page.current_window.resize_to(375, 1024)
  largeur = page.evaluate_script('[document.documentElement.scrollWidth, window.innerWidth]')
  Verify.evidence(DOSSIER, page, 'mobile', "scrollWidth/innerWidth=#{largeur}")
  raise "défilement horizontal #{largeur}" if largeur.first > largeur.last
ensure
  page.current_window.resize_to(1280, 1024)
end

def demarche_a_description_coupee
  Demarche.visibles.find do |candidate|
    ERB::Util.html_escape(candidate.chapo).size > 155 && candidate.chapo.truncate(155, separator: ' ').include?("'")
  end
end

def descriptions_lues(page)
  %w[meta[name=description] meta[property="og:description"]].map do |balise|
    page.evaluate_script("document.querySelector('#{balise}').content")
  end
end

def description_partagee(page)
  demarche = demarche_a_description_coupee
  page.visit("/demarches/#{demarche.slug}")
  description, partage = descriptions_lues(page)
  raise "description #{description.inspect}" if description.include?('&#39;') || description.exclude?("'")
  raise "og:description #{partage.inspect} != description" unless partage == description

  Verify.evidence(DOSSIER, page, 'description-fiche', "slug=#{demarche.slug} description=#{description.inspect}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Open') { ouvrir(page) }
  comptes = Verify.check('Feuilles') { feuilles(page) }
  Verify.check('À propos') { a_propos(page, comptes) }
  Verify.check('Mobile') { mobile(page) }
  Verify.check('Description') { description_partagee(page) }
  Verify.check('Proof') { Verify.captures_presentes(DOSSIER, %w[bureau mobile description-fiche]) }
end
