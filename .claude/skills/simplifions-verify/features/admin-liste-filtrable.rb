require_relative '../harness'

DOSSIER = 'admin-liste-filtrable'.freeze
FILTRE = 'Filtrer les intégrations'.freeze
CHAMP = 'demarche_integration_ids_filtre'.freeze

def preparer(nom)
  api = Integration.group(:integree_id).order(count_all: :desc).count.keys.first
  demarche = Demarche.create!(nom:)
  Recommandation.create!(demarche:, solution_id: api, niveau: :niveau_1)
  integrations = Integration.where(integree_id: api).includes(:integratrice, :integree).order(:id).to_a
  demarche.integrations = integrations.first(2)
  [demarche, integrations]
end

def compte(groupe) = groupe.find('[aria-live=polite]').text
def nb_visibles(groupe) = Verify.cases_affichees(groupe).size
def fond(page, groupe) = page.evaluate_script('getComputedStyle(arguments[0]).backgroundColor', groupe.find('[data-liste-filtrable-target=resultats]'))
def referme?(page, groupe, sans_cadre) = nb_visibles(groupe) == 2 && fond(page, groupe) == sans_cadre

def liste_courte(page)
  courte = Integration.order(:id).find { (1..10).cover?(it.demarches_proposees.count) }
  page.visit("/admin/integrations/#{courte.id}/edit")
  proposees = courte.demarches_proposees.count
  visibles = page.find(:fieldset, 'Démarches').all('.fr-checkbox-group label', visible: true).size
  raise "courte liste : #{visibles} cases visibles sur #{proposees}" unless visibles == proposees
  raise 'courte liste : champ de filtre présent' if page.has_field?('Filtrer les démarches', wait: 0)

  "intégration #{courte.id} : visibles=#{visibles} proposées=#{proposees} filtre=absent"
end

def groupes_de_vocabulaires(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  categories = page.all('fieldset fieldset > legend').map(&:text)
  raise "groupes de vocabulaires #{categories}" unless categories == ['Usager', 'Type de simplification', 'Catégorie de solution']

  aides = Verify.liens_d_aide(page.find('fieldset', text: 'Vocabulaires', match: :first)).size
  raise "#{aides} « ? » pour #{Vocabulaire.count} vocabulaires" unless aides == Vocabulaire.count

  categories
end

def cochees_seules(page, total)
  Verify.onglet(page, 'Intégrations')
  groupe = page.find('fieldset', text: FILTRE)
  coches = Verify.cases_affichees(groupe)
  raise "cases visibles sans filtre #{coches.size}" unless coches.size == 2 && coches.all?(&:checked?)
  raise "compte #{compte(groupe)}" unless compte(groupe) == "2 cochés sur #{total}"

  groupe
end

def tabs_pour_sortir(page, groupe)
  (1..10).find do
    page.send_keys :tab
    !page.evaluate_script("document.activeElement.closest('[data-controller=liste-filtrable]') === arguments[0]", groupe)
  end
end

def traversee_au_clavier(page, groupe)
  page.execute_script("document.getElementById('onglet-integrations-panneau').focus()")
  page.send_keys :tab
  raise 'Tab n’entre pas dans le filtre' unless Verify.focus_sur(page) == CHAMP
  raise 'Tab a ouvert la liste' unless nb_visibles(groupe) == 2

  tabs = tabs_pour_sortir(page, groupe)
  raise "#{tabs} Tab pour traverser la liste" unless tabs == 6

  Verify.evidence(DOSSIER, page, 'traversee-au-clavier', "tabs_du_filtre_a_la_suite=#{tabs} visibles=2")
end

def tous_au_clic(page, groupe, total, sans_cadre)
  groupe.find_field(FILTRE).click
  raise "cases visibles au clic #{nb_visibles(groupe)}" unless nb_visibles(groupe) == total
  raise 'compte changé au clic' unless compte(groupe) == "2 cochés sur #{total}"
  raise "pas de cadre gris (#{fond(page, groupe)})" if fond(page, groupe) == sans_cadre

  Verify.evidence(DOSSIER, page, 'tous-au-clic-encadres', "visibles=#{nb_visibles(groupe)} total=#{total} fond=#{fond(page, groupe)} fond_ferme=#{sans_cadre}")
end

def croix(page, groupe, sans_cadre)
  groupe.fill_in FILTRE, with: 'zzz'
  groupe.click_button 'Effacer le filtre des intégrations'
  raise 'croix : filtre non vide' unless groupe.find_field(FILTRE).value == ''
  raise "croix : #{nb_visibles(groupe)} cases" unless referme?(page, groupe, sans_cadre)
  raise 'croix : focus perdu' unless Verify.focus_sur(page) == CHAMP

  Verify.evidence(DOSSIER, page, 'croix-referme', "visibles=#{nb_visibles(groupe)} fond=#{fond(page, groupe)}")
end

def fleche_bas_puis_sortie(page, groupe, total, sans_cadre)
  page.send_keys :down
  raise 'flèche bas n’ouvre pas' unless nb_visibles(groupe) == total

  page.send_keys %i[shift tab]
  raise "sortie : #{nb_visibles(groupe)} cases" unless referme?(page, groupe, sans_cadre)

  Verify.evidence(DOSSIER, page, 'fleche-bas-puis-sortie-referme', "visibles=#{nb_visibles(groupe)}")
end

def atteindre_au_clavier(page, id)
  20.times do
    break if Verify.focus_sur(page) == id

    page.send_keys :tab
  end
  raise 'case cible jamais atteinte au clavier' unless Verify.focus_sur(page) == id
end

def saisir_le_libelle(page, groupe, cible)
  saisie = I18n.transliterate(cible.libelle).upcase.scan(/[[:alnum:]]+/).join(' ')
  groupe.fill_in FILTRE, with: saisie
  groupe.find('label', text: cible.libelle.squish, exact_text: true)
  page.send_keys :enter
  raise 'Entrée a envoyé le formulaire' if page.has_text?('enregistré', wait: 1)

  saisie
end

def filtrer_et_cocher(page, groupe, cible)
  saisie = saisir_le_libelle(page, groupe, cible)
  atteindre_au_clavier(page, "demarche_integration_ids_#{cible.id}")
  page.send_keys :space
  raise "compte #{compte(groupe)}" unless compte(groupe).include?('3 cochés')

  Verify.evidence(DOSSIER, page, 'filtre-et-coche-au-clavier', "saisie=#{saisie} compte=#{compte(groupe)}")
end

def cible_reste_affichee(groupe, cible)
  groupe.fill_in FILTRE, with: ''
  cochees = Verify.cases_affichees(groupe).select(&:checked?).pluck(:id)
  raise 'cible cachée après effacement' unless cochees.include?("demarche_integration_ids_#{cible.id}")
end

def integrations_en_base(demarche) = ActiveRecord::Base.uncached { Demarche.find(demarche.id).integration_ids.sort }

def enregistrer(page, groupe, demarche, cible)
  cible_reste_affichee(groupe, cible)
  page.click_button 'Enregistrer'
  page.assert_text "« #{demarche.nom} » enregistré."
  en_base = integrations_en_base(demarche)
  raise "en base #{en_base}, cible #{cible.id}" unless en_base.size == 3 && en_base.include?(cible.id)

  Verify.evidence(DOSSIER, page, 'enregistre', "en_base=#{en_base} cible=#{cible.id}")
end

def partir(page)
  page.find('fieldset', text: FILTRE).fill_in FILTRE, with: 'texte sans nom'
  page.click_link 'Annuler'
  page.assert_selector 'h1', text: 'Démarches'
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  demarche, integrations = preparer(nom)
  total = integrations.size
  Verify.login(page)
  Verify.check('Short list') { Verify.evidence(DOSSIER, page, 'courte-liste-entiere', liste_courte(page)) }
  categories = Verify.check('Groups') { groupes_de_vocabulaires(page, demarche) }
  groupe = Verify.check('Checked only') do
    cochees_seules(page, total).tap do |filtre|
      Verify.evidence(DOSSIER, page, 'cochees-seules', "visibles=2 compte=#{compte(filtre)} en_base=#{demarche.integration_ids.size} vocabulaires=#{categories.join(' | ')}")
    end
  end
  Verify.check('Tab passes through') { traversee_au_clavier(page, groupe) }
  sans_cadre = fond(page, groupe)
  Verify.check('Click shows all, framed') { tous_au_clic(page, groupe, total, sans_cadre) }
  Verify.check('Cross') { croix(page, groupe, sans_cadre) }
  Verify.check('ArrowDown, then leave') { fleche_bas_puis_sortie(page, groupe, total, sans_cadre) }
  Verify.check('Filter and keyboard') { filtrer_et_cocher(page, groupe, integrations.last) }
  Verify.check('Save') { enregistrer(page, groupe, demarche, integrations.last) }
  Verify.check('Leave') { partir(page) }
  Verify.check('Proof') do
    Verify.evidence(DOSSIER, page, 'filtre-ignore-en-partant', 'confirmation=aucune')
    Verify.logout(page)
  end
ensure
  Demarche.where(nom:).destroy_all
end
