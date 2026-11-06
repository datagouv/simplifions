require_relative '../harness'

DOSSIER = 'admin-listes'.freeze
ENTETES_INTEGRATIONS = ['Id', 'Solution', 'API ou jeu de données', 'Type d’intégration', 'Statut de l’intégration'].freeze

def lignes_affichees(page) = page.all('tbody tr').map { |ligne| ligne.all('td').map(&:text) }
def entetes(page) = page.all('thead th').map(&:text)

LISTE = "nav[aria-label='Liste des %s']".freeze

def noms_de_la_liste(page, des) = page.all("#{format(LISTE, des)} li a").map { it.find('.fr-text--bold').text }
def comptage(page) = page.find("#{format(LISTE, 'solutions')} [role=status]").text

def solutions_a_gauche(page)
  Verify.rubrique(page, 'Solutions')
  page.assert_selector format(LISTE, 'solutions')
  page.assert_text 'Choisissez une solution dans la liste'
  raise 'tableau ou pagination' if page.has_css?('table, .fr-pagination', wait: 0)

  lignes = noms_de_la_liste(page, 'solutions').size
  raise "lignes #{lignes} != #{Solution.count}" unless lignes == Solution.count && comptage(page) == "#{Solution.count} solutions"

  Verify.evidence(DOSSIER, page, 'solutions-liste', "solutions=#{Solution.count} lignes=#{lignes} comptage=#{comptage(page)}")
end

def recherche(page, integree)
  Verify.rechercher(page, integree.nom)
  noms = noms_de_la_liste(page, 'solutions')
  attendus = Solution.recherche(integree.nom).order(:nom).map(&:nom)
  raise "recherche #{noms} != #{attendus}" unless noms.sort == attendus.sort

  Verify.evidence(DOSSIER, page, 'solutions-recherche', "q=#{integree.nom} lignes=#{noms.size} en_base=#{attendus.size}")
end

def liste_gardee_sur_la_fiche(page)
  page.visit('/admin/demarches')
  page.select 'Publiées', from: 'État'
  page.click_button 'Filtrer'
  page.assert_current_path(/etat=publiees/, url: true)
  attendu = Demarche.where(visible: true).order(:id).first
  nom = attendu.nom
  Verify.ouvrir_depuis_la_liste(page, nom)
  page.assert_current_path(%r{/admin/demarches/\d+/edit\?.*etat=publiees}, url: true)
  verifier_fiche_et_liste(page, nom)
end

def verifier_fiche_et_liste(page, nom)
  page.assert_selector 'h1', text: nom
  page.assert_no_text 'Choisissez une démarche dans la liste'
  ouverte = page.all("#{format(LISTE, 'démarches')} a[aria-current=page]")
  raise "aria-current #{ouverte.size}" unless ouverte.size == 1 && ouverte.first.text.include?(nom)

  etat = page.find_field('État').value
  raise "état #{etat}" unless etat == 'publiees' && page.find("#{format(LISTE, 'démarches')} [role=status]").text.match?(/\A\d+ démarches?\z/)

  Verify.evidence(DOSSIER, page, 'fiche-liste-gardee', "url=#{URI(page.current_url).request_uri} ouverte=#{ouverte.first.text.squish} etat=#{etat}")
end

def invite_et_liste(page)
  Verify.rubrique(page, 'Démarches')
  page.assert_selector format(LISTE, 'démarches')
  page.assert_text 'Choisissez une démarche dans la liste'
  lignes = noms_de_la_liste(page, 'démarches').size
  raise "lignes #{lignes}" unless lignes == Demarche.count && page.has_no_css?('table', wait: 0)

  Verify.evidence(DOSSIER, page, 'demarches-liste', "lignes=#{lignes} en_base=#{Demarche.count}")
end

def recherche_croisee(reco) = "#{reco.demarche.nom.split.first} #{reco.solution.nom.split.last}"

def recherche_jointe(page)
  page.visit('/admin/recommandations')
  reco = Recommandation.includes(:demarche, :solution).order(:id).first
  Verify.rechercher(page, recherche_croisee(reco))
  page.assert_selector 'tbody a', text: reco.libelle
  Verify.evidence(DOSSIER, page, 'recommandations-recherche', "q=#{page.find_field('Rechercher').value} #{lignes_et_visibilite(page)}")
end

def lignes_et_visibilite(page)
  visibles = page.all('tbody tr').map { |ligne| ligne.all('td')[2].text }.tally
  "lignes=#{lignes_affichees(page).size} visible=#{visibles}"
end

def une_seule_page(page)
  raise 'pagination organisations' if page.has_css?('.fr-pagination', wait: 0)

  lignes = lignes_affichees(page).size
  raise "organisations #{lignes} != #{Organisation.count}" unless lignes == Organisation.count

  lignes
end

def organisations(page)
  Verify.rubrique(page, 'Organisations')
  lignes = une_seule_page(page)
  organisation = Organisation.where.not(nom_long: [nil, '']).order(:id).first
  page.assert_selector 'tbody tr', text: "#{organisation.nom} #{organisation.nom_long}"
  Verify.evidence(DOSSIER, page, 'organisations-une-page', "lignes=#{lignes} en_base=#{Organisation.count} nom_long=#{organisation.nom_long}")
end

def ligne_attendue(integration)
  [integration.id.to_s, integration.integratrice.libelle_admin, integration.integree.libelle_admin, integration.type_libelle, integration.statut.to_s]
end

def integrations(page)
  page.visit('/admin/integrations')
  attendu = ligne_attendue(Integration.includes(:integratrice, :integree).order(:id).first)
  raise "entetes #{entetes(page)}" unless entetes(page) == ENTETES_INTEGRATIONS

  premiere = lignes_affichees(page).first
  raise "intégration #{premiere} != #{attendu}" unless premiere == attendu

  Verify.evidence(DOSSIER, page, 'integrations-colonnes', "premiere=#{attendu.join(' | ')}")
end

def ligne_avec_icone(page, demarche)
  gras = page.find("#{format(LISTE, 'démarches')} li a", text: demarche.nom).find('.fr-text--bold')
  icone_masquee = gras.has_css?('[aria-hidden=true]', text: demarche.icone)
  raise "icône #{gras.text}" unless gras.text == "#{demarche.icone} #{demarche.nom}" && icone_masquee

  gras.text
end

def demarches(page)
  Verify.rubrique(page, 'Démarches')
  demarche = Demarche.where.not(icone: [nil, '']).order(:id).first
  Verify.rechercher(page, demarche.nom)
  Verify.evidence(DOSSIER, page, 'demarche-icone', "demarche=#{demarche.id} ligne=#{ligne_avec_icone(page, demarche)}")
end

def recherche_vide_a_gauche(page)
  Verify.rubrique(page, 'Démarches')
  Verify.rechercher(page, 'zzz-introuvable')
  liste = page.find(format(LISTE, 'démarches'))
  statut = liste.find('[role=status]').text
  raise "statut #{statut}" unless statut == 'Aucune démarche ne contient « zzz-introuvable ».' && liste.has_link?('Effacer la recherche') && liste.has_no_css?('li a', wait: 0)

  Verify.evidence(DOSSIER, page, 'demarches-recherche-vide', "statut=#{statut}")
end

def recherche_sans_resultat(page)
  Verify.rubrique(page, 'Vocabulaires')
  Verify.rechercher(page, 'zzz-introuvable')
  statut = page.find('[role=status]').text
  raise "statut #{statut}" unless statut == 'Aucun vocabulaire ne contient « zzz-introuvable ».' && page.has_no_css?('table', wait: 0)

  Verify.evidence(DOSSIER, page, 'recherche-sans-resultat', "statut=#{statut}")
  effacer_la_recherche(page)
end

def effacer_la_recherche(page)
  page.click_link 'Effacer la recherche'
  page.assert_current_path('/admin/vocabulaires')
  lignes = [Vocabulaire.count, 50].min
  page.assert_selector 'tbody tr', count: lignes
  Verify.evidence(DOSSIER, page, 'recherche-effacee', "url=#{page.current_path} lignes=#{lignes} en_base=#{Vocabulaire.count}")
end

Verify.drive(__FILE__) do |page|
  integree = Solution.joins(:integrations_comme_integree).order(:id).first
  Verify.login(page)
  Verify.check('Solutions list on the left') { solutions_a_gauche(page) }
  Verify.check('Search') { recherche(page, integree) }
  Verify.check('Démarches list and prompt') { invite_et_liste(page) }
  Verify.check('Filtered row opens the fiche') { liste_gardee_sur_la_fiche(page) }
  Verify.check('Search without result on the left') { recherche_vide_a_gauche(page) }
  Verify.check('Joined search') { recherche_jointe(page) }
  Verify.check('Organisations') { organisations(page) }
  Verify.check('Intégrations') { integrations(page) }
  Verify.check('Search without result') { recherche_sans_resultat(page) }
  Verify.check('Démarches') { demarches(page) }
  Verify.check('Proof') { Verify.logout(page) }
end
