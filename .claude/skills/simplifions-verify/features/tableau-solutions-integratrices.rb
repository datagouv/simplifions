require_relative '../harness'

DOSSIER = 'tableau-solutions-integratrices'.freeze
DONNEES = 'Le plus de données intégrées'.freeze
MESURES_MOBILE = <<~JS.freeze
  (() => { const c = document.querySelector('#solutions-integratrices table').closest('.fr-table__container')
           const ligne = c.querySelector('tbody tr')
           c.scrollLeft = 400
           const bords = [...ligne.children].slice(0, 2).map((cellule) => Math.round(cellule.getBoundingClientRect().left))
           return [document.documentElement.scrollWidth, document.documentElement.clientWidth, c.scrollWidth, c.clientWidth,
                   Math.round(c.scrollLeft), Math.round(c.getBoundingClientRect().left), ...bords] })()
JS

def listes_affichees(panneau) = panneau.all('[data-tri-solutions-target=liste]').map { |liste| liste.all(':scope > [data-nom]').map { it['data-nom'] } }
def par_titre(noms) = noms.map { |liste| liste.sort_by { I18n.transliterate(it).downcase } }
def annonce(tableau, cellule) = (cellule['headers'].split.map { tableau.find("th##{it}").text.squish } << cellule.text(:all).squish)
def en_lignes(listes) = listes.map { it.join(', ') }.join(' | ')
def en_annonces(annonces) = annonces.map { it.join(' / ') }.join(' || ')

def trier_par(page, panneau, choix, attendu, etape)
  panneau.select(choix, from: 'Trier par :')
  affichees = listes_affichees(panneau)
  raise "#{etape} : #{affichees.inspect} != #{attendu.inspect}" unless affichees == attendu

  Verify.evidence(DOSSIER, page, etape, "tri=#{choix.inspect} listes=#{en_lignes(affichees)}")
end

def arrivee(page, demarche)
  page.current_window.resize_to(1280, 1024)
  page.visit("/demarches/#{demarche.slug}")
  page.find('[role=tab][aria-controls=solutions-integratrices]').click
  panneau = page.find('#solutions-integratrices.fr-tabs__panel--selected')
  raise 'Cartes non coché' unless panneau.find_field('Cartes', visible: :all).checked?
  raise 'tri par défaut' unless panneau.find_field('Trier par :').value == 'integrees'
  raise 'phrase d’ordre encore là' if panneau.has_text?('Les solutions sont classées', wait: 0)

  page.assert_no_selector('#solutions-integratrices table')
  panneau
end

def passer_en_tableau(page, panneau, servi)
  panneau.choose('Tableau comparatif', allow_label_click: true)
  page.assert_no_selector('#solutions-integratrices .solution-integratrice-card')
  tableau = panneau.all('table', count: servi.size).first
  raise "tableau pas trié par titre : #{listes_affichees(panneau)}" unless listes_affichees(panneau) == par_titre(servi)

  Verify.evidence(DOSSIER, page, 'tableau-titre', "listes=#{en_lignes(listes_affichees(panneau))}")
  trier_par(page, panneau, DONNEES, servi, 'tableau-donnees')
  tableau
end

def titres_des_groupes(demarche) = demarche.groupes_donnees_utiles.map { ApplicationController.helpers.titre_groupe_donnees(it.first) }

def colonnes_du_tableau(demarche, tableau)
  groupes = tableau.all('thead th[scope=colgroup]').map(&:text)
  colonnes = tableau.all('thead th[scope=col]').size - 2
  utiles = demarche.donnees_utiles.size
  raise "groupes #{groupes} != #{titres_des_groupes(demarche)}" unless groupes == titres_des_groupes(demarche)
  raise "colonnes #{colonnes} != utiles #{utiles}" unless colonnes == utiles
  raise 'tri par en-tête' if tableau.has_button?(text: /Trier/, wait: 0)

  "slug=#{demarche.slug} groupes=#{groupes.join(' | ')} colonnes=#{colonnes} utiles_base=#{utiles}"
end

def annonce_lisible?(annonce) = annonce.size == 4 && annonce.last.match?(/\A(Non intégrée|Intégrée)\z/)

def cases_non_et_integree(cases) = [cases.find { it.text(:all).include?('Non') }, cases.find { it.text(:all).squish == 'Intégrée' }].compact

def annonces_des_cases(tableau)
  cases = tableau.first('tbody tr').all('td')[1..]
  annonces = cases_non_et_integree(cases).map { annonce(tableau, it) }
  raise "annonces #{annonces.inspect}" unless annonces.any? && annonces.all? { annonce_lisible?(it) }

  "role_cellule=#{cases.first.native.aria_role} annonces=#{en_annonces(annonces)}"
end

def annonce_puis_retour_aux_cartes(page, panneau, tableau, colonnes)
  Verify.evidence(DOSSIER, page, 'colonnes', "#{colonnes} #{annonces_des_cases(tableau)}")
  panneau.choose('Cartes', allow_label_click: true)
  page.assert_no_selector('#solutions-integratrices table')
end

def tableau_mobile_ouvert(page, demarche)
  page.current_window.resize_to(375, 800)
  page.visit("/demarches/#{demarche.slug}#solutions-integratrices")
  panneau = page.find('#solutions-integratrices.fr-tabs__panel--selected')
  panneau.choose('Tableau comparatif', allow_label_click: true)
  page.scroll_to(panneau.first('table'), align: :top)
  page.evaluate_script(MESURES_MOBILE)
end

def verifier_le_defilement(mesures)
  page_large, fenetre, tableau_large, cadre, defile, gauche, nom, compteur = mesures
  raise "la page déborde : #{page_large} > #{fenetre}" if page_large > fenetre
  raise "le tableau ne défile pas : #{mesures}" unless tableau_large > cadre && defile.positive?
  raise "nom sorti ou compteur figé : #{mesures}" unless (nom - gauche).abs <= 2 && compteur < nom
end

def tableau_mobile(page, demarche)
  mesures = tableau_mobile_ouvert(page, demarche)
  verifier_le_defilement(mesures)
  page_large, fenetre, tableau_large, cadre, defile, gauche, nom, compteur = mesures
  Verify.evidence(DOSSIER, page, 'mobile',
    "page=#{page_large}/#{fenetre} tableau=#{tableau_large}/#{cadre} defilement=#{defile} bord_cadre=#{gauche} nom=#{nom} compteur=#{compteur}")
end

def sans_choix_ni_tri(solutions)
  raise 'choix affiché sans JS' if solutions.has_text?('Tableau comparatif', wait: 0)
  raise 'tri affiché sans JS' if solutions.has_field?('Trier par :', wait: 0)
end

def tableau_sans_js(demarche)
  page = Verify.session(javascript: false)
  page.visit("/demarches/#{demarche.slug}")
  solutions = page.find('#solutions-integratrices')
  page.scroll_to(solutions.first('table'), align: :top)
  cartes = solutions.all('.solution-integratrice-card').size
  lignes = solutions.all('tbody tr').size
  raise "sans JS cartes=#{cartes} lignes=#{lignes}" unless cartes.positive? && cartes == lignes

  sans_choix_ni_tri(solutions)
  Verify.evidence(DOSSIER, page, 'sans-js', "cartes=#{cartes} lignes=#{lignes} choix=masque tri=masque")
ensure
  page&.quit
end

Verify.drive(__FILE__) do |page|
  demarche = Demarche.visibles.order(:id).find { it.integratrices_par_categorie.any? }
  servi = demarche.integratrices_par_categorie.values.map { |solutions| solutions.map(&:nom) }
  panneau = Verify.check('Arrival') { arrivee(page, demarche) }
  Verify.check('Sort cards') do
    trier_par(page, panneau, DONNEES, servi, 'cartes-donnees')
    trier_par(page, panneau, 'Titre', par_titre(servi), 'cartes-titre')
  end
  tableau = Verify.check('Table') { passer_en_tableau(page, panneau, servi) }
  colonnes = Verify.check('Columns') { colonnes_du_tableau(demarche, tableau) }
  Verify.check('Announcement') { annonce_puis_retour_aux_cartes(page, panneau, tableau, colonnes) }
  Verify.check('Mobile') { tableau_mobile(page, demarche) }
  Verify.check('No JS') do
    page.quit
    tableau_sans_js(demarche)
  end
end
