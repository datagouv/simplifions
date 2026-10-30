require_relative '../harness'

DOSSIER = 'fiche-donnees-integrees'.freeze

CARTES_PAR_GRILLE = <<~JS.freeze
  [...document.querySelectorAll('section.fr-accordion .fr-collapse .fr-grid-row')].map(grille =>
    [...grille.querySelectorAll('.solution-integratrice-card')].map(carte => {
      const compte = carte.querySelector('.solution-integratrice-card__couverture > .integration-indicator__count')
      const total = carte.querySelector('.solution-integratrice-card__total .integration-indicator__count')
      const valeur = !compte ? 0 : compte.classList.contains('fr-icon-check-line') ? 1 : parseInt(compte.textContent, 10)
      return [carte.querySelector('.solution-integratrice-card__title').textContent.replace(/\s+/g, ' ').trim(), valeur, total && total.textContent]
    })).filter(cartes => cartes.length > 0)
JS

Fenetre = Struct.new(:demarche, :oeil, :carte, :modale)

def demarche_avec_integratrices
  Demarche.visibles.order(:id).find { it.donnees_utiles.any? && it.recommandations_publiees.any? { |reco| reco.solutions_integratrices.exists? } }
end

def ouvrir_la_fenetre(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  section = page.find('#donnees-disponibles')
  oeil = section.first('.solution-integratrice-card button', text: 'Voir les données intégrées par', visible: :all)
  section.find("button.fr-accordion__btn[aria-controls='#{oeil.ancestor('.fr-collapse', visible: :all)[:id]}']").click
  carte = oeil.ancestor('.solution-integratrice-card')
  carte.assert_selector('.solution-integratrice-card__total')
  texte = carte.text.squish
  oeil.click
  Fenetre.new(demarche, oeil, texte, page.find("dialog##{oeil['aria-controls']}[open]"))
end

def lignes_cochees(modale)
  lignes = modale.all('li', visible: :all).map { it.text(:all) }
  "#{lignes.count { it.include?(': intégrée') }}/#{lignes.size}"
end

def fenetres_et_yeux(page)
  [page.all('dialog.fr-modal', visible: :all).size, page.all('.solution-integratrice-card button.fr-icon-eye-line', visible: :all).size]
end

def total_de_la_fenetre(fenetre) = fenetre.demarche.couverture(Solution.find_by!(nom: fenetre.modale.find('h2').text)).join('/')

def verifier_le_total(fenetre, total)
  raise "carte sans le total #{total} : #{fenetre.carte}" unless fenetre.carte.include?("#{total} API ou jeux de données au total")
  raise "fenêtre sans le total #{total}" unless fenetre.modale.text.squish.include?("Sur l’ensemble du cas d’usage : #{total}")
  raise "#{lignes_cochees(fenetre.modale)} lignes != #{total}" unless lignes_cochees(fenetre.modale) == total
end

def prouver_les_totaux(page, fenetre)
  total = total_de_la_fenetre(fenetre)
  verifier_le_total(fenetre, total)
  fenetres, yeux = fenetres_et_yeux(page)
  raise "#{fenetres} fenêtres pour #{yeux} yeux" unless fenetres == yeux

  Verify.evidence(DOSSIER, page, 'modale-ouverte', "slug=#{fenetre.demarche.slug} solution=#{fenetre.modale.find('h2').text.inspect} " \
                                                   "total=#{total} carte=#{fenetre.carte.inspect} fenetres=#{fenetres} yeux=#{yeux}")
end

def montrer_le_detail(page, ligne)
  ligne.find('summary').click
  detail = ligne.find('details[open] > div').text
  raise 'détail vide' if detail.blank?

  Verify.evidence(DOSSIER, page, 'detail-ouvert', "ligne=#{ligne.find('summary').text.inspect} detail=#{detail.squish.inspect}")
  detail
end

def montrer_puis_masquer_le_detail(page, modale)
  ligne = modale.first('li details', minimum: 1).ancestor('li')
  detail = montrer_le_detail(page, ligne)
  ligne.find('summary').click
  ligne.assert_no_selector('details[open]')
  raise 'détail encore visible' if ligne.has_text?(detail.lines.first.strip, wait: 0)

  Verify.evidence(DOSSIER, page, 'detail-masque', "ligne=#{ligne.find('summary').text.inspect} detail_visible=false")
end

def fermer_au_clavier(page, fenetre)
  page.send_keys(:escape)
  page.assert_no_selector("dialog##{fenetre.modale[:id]}[open]")
  focus = page.evaluate_script('document.activeElement.getAttribute("aria-controls")')
  raise "focus sur #{focus.inspect}" unless focus == fenetre.oeil['aria-controls']

  Verify.evidence(DOSSIER, page, 'modale-fermee', "focus=#{focus}")
end

def grilles_de_cartes(page)
  Demarche.visibles.order(:id).flat_map do |demarche|
    page.visit("/demarches/#{demarche.slug}")
    page.evaluate_script(CARTES_PAR_GRILLE).map { [demarche.slug, it] }
  end
end

def verifier_le_classement(slug, cartes, rangs_par_nom)
  inconnus = cartes.map(&:first) - rangs_par_nom
  raise "#{slug} : sans nom en base #{inconnus}" unless inconnus.empty?
  raise "#{slug} : cartes mal classées #{cartes.inspect}" unless cartes == cartes.sort_by { |nom, compte| [-compte, rangs_par_nom.index(nom)] }
end

def classee_autrement_par_les_totaux?(cartes) = cartes != cartes.sort_by.with_index { |(_, _, total), rang| [-total.to_i, rang] }

def grille_parlante(grilles)
  grilles.find { |_, cartes| classee_autrement_par_les_totaux?(cartes) } || grilles.max_by { |_, cartes| cartes.map { it[1] }.uniq.size }
end

def verifier_l_ordre(page)
  grilles = grilles_de_cartes(page)
  rangs_par_nom = Solution.order(:nom).pluck(:nom).map(&:squish).uniq
  grilles.each { |slug, cartes| verifier_le_classement(slug, cartes, rangs_par_nom) }
  slug, cartes = grille_parlante(grilles)
  page.visit("/demarches/#{slug}")
  Verify.evidence(DOSSIER, page, 'cartes-classees',
    "grilles=#{grilles.size} plus_variee=#{slug} cartes=#{cartes.map { |nom, compte, total| "#{nom} #{compte} (total #{total})" }.inspect}")
end

Verify.drive(__FILE__) do |page|
  fenetre = Verify.check('Open') { ouvrir_la_fenetre(page, demarche_avec_integratrices) }
  Verify.check('Proof') { prouver_les_totaux(page, fenetre) }
  Verify.check('Detail') { montrer_puis_masquer_le_detail(page, fenetre.modale) }
  Verify.check('Close') { fermer_au_clavier(page, fenetre) }
  Verify.check('Order') { verifier_l_ordre(page) }
end
