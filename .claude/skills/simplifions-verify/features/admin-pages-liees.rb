require_relative '../harness'

DOSSIER = 'admin-pages-liees'.freeze
FILTRE = 'Filtrer les fournisseurs de services'.freeze

def zone_sans_defilement(page, id)
  page.evaluate_script("(z => [z.rows, z.scrollHeight, z.clientHeight, z.scrollHeight <= z.clientHeight + 2])(document.getElementById('#{id}'))")
end

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

def zone_de_texte(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  zone = zone_sans_defilement(page, 'demarche_contexte')
  raise "contexte défile #{zone}" unless zone.last

  aide = page.find('label[for=demarche_contexte] .fr-hint-text').text
  raise "aide #{aide}" unless aide == 'Markdown accepté'

  Verify.evidence(DOSSIER, page, 'zone-de-texte', "caracteres=#{demarche.contexte.size} rows,scrollHeight,clientHeight,sans_defilement=#{zone.join(',')} aide=#{aide}")
end

def page_publique(page, demarche)
  lien = page.find_link('Voir la page publique')
  publique = page.window_opened_by { lien.click }
  titre = page.within_window(publique) do
    page.assert_current_path("/demarches/#{demarche.slug}")
    page.find('h1').text
  end
  Verify.evidence(DOSSIER, page, 'page-publique', "title=#{lien[:title]} target=#{lien[:target]} ouvert=/demarches/#{demarche.slug} h1=#{titre}")
  publique.close
end

def fiche_liee(page, zone, ligne, chemin)
  fiche = page.window_opened_by { Verify.lien_nomme(zone, "Fiche de #{ligne.nom} (nouvel onglet)").click }
  h1 = page.within_window(fiche) do
    page.assert_current_path(chemin)
    page.assert_selector :link, 'Modifier'
    page.find('h1').text
  end
  fiche.close
  h1
end

def fiche_en_nouvel_onglet(page, zone, ligne, chemin, formulaire)
  h1 = fiche_liee(page, zone, ligne, chemin)
  raise 'le formulaire a été quitté' unless page.current_path == formulaire

  Verify.evidence(DOSSIER, page, "fiche-#{ligne.model_name.element}", "ouvert=#{chemin} h1=#{h1} formulaire=#{page.current_path}")
end

def liens_des_fournisseurs(page, demarche)
  groupe = page.find('fieldset', text: FILTRE)
  liens = Verify.liens_d_aide(groupe)
  attendus = demarche.types_acteurs.map { |t| "Fiche de #{t.nom} (nouvel onglet)" }
  raise "liens #{liens} pour #{demarche.types_acteurs.map(&:nom)}" unless liens.sort == attendus.sort

  Verify.evidence(DOSSIER, page, 'referentiel-trois-colonnes', "liens=#{liens.join(' | ')} #{trois_colonnes(page)}")
  groupe
end

def referentiel(page, demarche)
  acteur = demarche.types_acteurs.order(:nom).first
  groupe = liens_des_fournisseurs(page, demarche)
  formulaire = "/admin/demarches/#{demarche.id}/edit"
  fiche_en_nouvel_onglet(page, groupe, acteur, "/admin/types_acteurs/#{acteur.id}", formulaire)
  vocabulaire = Vocabulaire.order(:id).first
  fiche_en_nouvel_onglet(page, page, vocabulaire, "/admin/vocabulaires/#{vocabulaire.id}", formulaire)
end

def afficher_a(page, demarche, largeur)
  page.current_window.resize_to(largeur, 1024)
  page.visit("/admin/demarches/#{demarche.id}/edit")
end

def referentiel_etroit(page, demarche)
  afficher_a(page, demarche, 375)
  Verify.evidence(DOSSIER, page, 'referentiel-375', trois_colonnes(page, 1))
  afficher_a(page, demarche, 320)
  Verify.evidence(DOSSIER, page, 'etroit-320', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  groupe = page.find('fieldset', text: FILTRE)
  groupe.fill_in FILTRE, with: 'fiche de'
  filtre = Verify.cases_affichees(groupe).size
  raise "le filtre trouve le texte du lien (#{filtre})" unless filtre.zero?

  Verify.evidence(DOSSIER, page, 'filtre-ignore-le-lien', "saisie=fiche de cases_affichees=#{filtre}")
ensure
  page.current_window.resize_to(1280, 1024)
end

def recommandation_vers_solution(page)
  recommandation = Recommandation.first
  page.visit("/admin/recommandations/#{recommandation.id}/edit")
  Verify.lien_nomme(page, "Voir la fiche #{recommandation.solution.libelle_admin}").click
  page.assert_current_path("/admin/solutions/#{recommandation.solution_id}/edit")
  Verify.evidence(DOSSIER, page, 'recommandation-vers-solution', "url=#{page.current_path} h1=#{page.find('h1').text}")
end

Verify.drive(__FILE__) do |page|
  demarche = Demarche.visibles.where.not(slug: [nil, '']).max_by { |ligne| ligne.contexte.to_s.size }
  Verify.login(page)
  Verify.check('Text area') { zone_de_texte(page, demarche) }
  Verify.check('Public page') { page_publique(page, demarche) }
  Verify.check('Référentiel') do
    referentiel(page, demarche)
    referentiel_etroit(page, demarche)
  end
  Verify.check('Recommandation') { recommandation_vers_solution(page) }
  Verify.check('Proof') { Verify.logout(page) }
end
