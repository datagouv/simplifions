require_relative '../harness'

DOSSIER = 'admin-recommandations-en-ligne'.freeze

def api_a_recommander(demarche)
  Solution.where(categorie: 'api').where.not(id: demarche.recommandations.select(:solution_id)).reject(&:privee?).first
end

def contexte
  demarche = Demarche.visibles.where.not(slug: [nil, '']).max_by { |ligne| ligne.recommandations.count }
  reco = demarche.recommandations.visibles.par_niveau_et_ordre.first
  { demarche:, reco:, solution: api_a_recommander(demarche), nom: "la recommandation #{reco.solution.libelle_admin}",
    avant: demarche.recommandations.count }
end

def cartes_publiques(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  page.all('.reco-card').map(&:text)
end

def onglet_recommandations(page, demarche)
  page.visit("/admin/demarches/#{demarche.id}/edit")
  Verify.onglet(page, 'Recommandations')
end

def enregistrer_l_ordre(page, nom, ordre)
  page.find_field("Ordre de #{nom}").fill_in(with: ordre)
  yield if block_given?
  page.click_button "Enregistrer #{nom}"
end

def ligne_en_brouillon(page, ctx)
  reco = ctx[:reco]
  onglet_recommandations(page, ctx[:demarche])
  enregistrer_l_ordre(page, ctx[:nom], '77') { raise 'la ligne a marqué la fiche' unless Verify.enregistrer_desactive?(page) }
  page.assert_selector '#message-recommandations .fr-valid-text', text: 'brouillon enregistré'
  page.find("tr#recommandation_#{reco.id}").assert_selector '.fr-badge--new', text: /brouillon/i
  preuve_du_brouillon(page, reco)
end

def preuve_du_brouillon(page, reco)
  ActiveRecord::Base.uncached do
    Verify.evidence(DOSSIER, page, 'ligne-modifiee', "focus=#{Verify.focus_sur(page)} fiche_grisee=#{Verify.enregistrer_desactive?(page)} " \
                                                     "ordre_en_base=#{reco.reload.ordre} ordre_du_brouillon=#{reco.brouillon&.dig('ordre')}")
  end
end

def fiche_gardee(page, ctx)
  Verify.onglet(page, 'Fiche')
  page.fill_in 'Description courte', with: "#{ctx[:demarche].description_courte} "
  Verify.onglet(page, 'Recommandations')
  enregistrer_l_ordre(page, ctx[:nom], '78')
  page.assert_selector '#message-recommandations .fr-valid-text'
  raise 'la fiche modifiée a été oubliée' if Verify.enregistrer_desactive?(page)

  Verify.evidence(DOSSIER, page, 'fiche-modifiee-garde', "confirmation=aucune fiche_grisee=#{Verify.enregistrer_desactive?(page)}")
end

def erreur_de_ligne(page)
  page.select 'Solution recommandée', from: 'Type de recommandation de la nouvelle recommandation (obligatoire)'
  page.click_button 'Ajouter la nouvelle recommandation'
  erreur = page.find('#erreurs_recommandation', text: 'Choisissez une solution')
  Verify.evidence(DOSSIER, page, 'erreur-ligne', "erreur=#{erreur.text} focus=#{Verify.focus_sur(page)} " \
                                                 "decrit_par=#{page.find('#enregistrer_recommandation')['aria-describedby']}")
end

def remplir_la_nouvelle(page, solution)
  page.select solution.libelle_admin, from: 'Solution de la nouvelle recommandation (obligatoire)'
  page.find_field('Ordre de la nouvelle recommandation').fill_in(with: '99')
  page.click_button 'Ajouter la nouvelle recommandation'
end

def ajouter(page, ctx)
  solution = ctx[:solution]
  remplir_la_nouvelle(page, solution)
  page.assert_selector '#message-recommandations .fr-valid-text', text: solution.libelle_admin
  ctx[:creee] = ActiveRecord::Base.uncached { ctx[:demarche].recommandations.find_by!(solution:) }
  page.assert_selector "tr#recommandation_#{ctx[:creee].id}"
  preuve_de_l_ajout(page, ctx)
end

def preuve_de_l_ajout(page, ctx)
  vide = page.find('tr#new_recommandation select[name="recommandation[solution_id]"]').value
  en_base = ActiveRecord::Base.uncached { ctx[:demarche].recommandations.count }
  Verify.evidence(DOSSIER, page, 'ajoutee', "lignes=#{page.all('tbody tr').size} en_base=#{en_base} avant=#{ctx[:avant]} " \
                                            "visible=#{ctx[:creee].visible} ligne_vide=#{vide.inspect} focus=#{Verify.focus_sur(page)}")
end

def page_publique_inchangee(page, ctx)
  page.accept_confirm('Quitter sans enregistrer les modifications ?') { page.click_link 'Annuler' }
  page.assert_selector 'h1', text: 'Démarches'
  apres = cartes_publiques(page, ctx[:demarche])
  Verify.evidence(DOSSIER, page, 'page-publique', "inchangee=#{apres == ctx[:cartes]} cartes=#{apres.size}")
  raise "page publique changée : #{ctx[:cartes].size} cartes avant, #{apres.size} après" unless apres == ctx[:cartes]
end

def mesurer_a(page, demarche, largeur)
  page.current_window.resize_to(largeur, 1024)
  page.visit("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
  defilement = page.evaluate_script("(c => [c.scrollWidth, c.clientWidth])(document.querySelector('.fr-table__content'))")
  raise "tableau à #{largeur} px : #{defilement.join(' > ')}" if defilement.first > defilement.last

  Verify.evidence(DOSSIER, page, "largeur-#{largeur}", "tableau_defilable=#{defilement.first} visible=#{defilement.last}")
end

def largeurs(page, demarche)
  [1280, 1024].each { mesurer_a(page, demarche, it) }
  page.current_window.resize_to(375, 812)
  page.visit("/admin/demarches/#{demarche.id}/edit?onglet=recommandations")
  Verify.evidence(DOSSIER, page, 'etroit-375', "defilement_horizontal=#{page.evaluate_script('document.documentElement.scrollWidth > innerWidth')}")
  page.current_window.resize_to(1280, 1024)
end

def abandonner_le_brouillon(page, ctx)
  page.click_link "Modifier #{ctx[:nom]}"
  page.accept_confirm { page.click_button 'Abandonner le brouillon' }
  page.assert_text 'abandonné'
  page.visit("/admin/demarches/#{ctx[:demarche].id}/edit?onglet=recommandations")
end

def supprimer_l_ajoutee(page, ctx)
  creee = ctx[:creee]
  poubelle = "Supprimer la recommandation #{ctx[:solution].libelle_admin}"
  page.dismiss_confirm("#{poubelle} ?") { page.click_button poubelle }
  page.assert_selector "tr#recommandation_#{creee.id}"
  raise 'refuser la confirmation a supprimé' unless ActiveRecord::Base.uncached { Recommandation.exists?(creee.id) }

  page.accept_confirm("#{poubelle} ?") { page.click_button poubelle }
  page.assert_selector '#message-recommandations .fr-valid-text', text: 'supprimé'
  page.assert_no_selector "tr#recommandation_#{creee.id}"
end

def focus_apres_suppression(page)
  focus = page.evaluate_script("document.activeElement.closest('#message-recommandations')?.textContent?.trim()")
  raise "focus perdu après suppression (#{Verify.focus_sur(page).inspect})" unless focus&.include?('supprimé')

  focus
end

def etat_revenu(ctx)
  ActiveRecord::Base.uncached do
    compte = ctx[:demarche].recommandations.count
    raise "#{compte} recommandations au lieu de #{ctx[:avant]}" unless compte == ctx[:avant]
    raise "brouillon resté : #{ctx[:reco].reload.brouillon.inspect}" if ctx[:reco].reload.brouillon?
  end
end

def defaire(page, ctx)
  abandonner_le_brouillon(page, ctx)
  supprimer_l_ajoutee(page, ctx)
  ctx[:focus] = focus_apres_suppression(page)
  etat_revenu(ctx)
end

def preuve(page, ctx)
  ActiveRecord::Base.uncached do
    Verify.evidence(DOSSIER, page, 'defait', "url=#{page.current_path} en_base=#{ctx[:demarche].recommandations.count} avant=#{ctx[:avant]} " \
                                             "brouillon=#{ctx[:reco].reload.brouillon.inspect} focus=#{ctx[:focus]}")
  end
  Verify.logout(page)
end

def nettoyer(ctx)
  ActiveRecord::Base.uncached do
    ctx[:demarche].recommandations.where(ordre: 99, grist_id: nil, solution: ctx[:solution]).destroy_all
    ctx[:reco].reload.abandonner_brouillon! if ctx[:reco].reload.brouillon?
  end
end

Verify.drive(__FILE__) do |page|
  ctx = contexte
  ctx[:cartes] = cartes_publiques(page, ctx[:demarche])
  Verify.login(page)
  Verify.check('Row') { ligne_en_brouillon(page, ctx) }
  Verify.check('Fiche kept') { fiche_gardee(page, ctx) }
  Verify.check('Error') { erreur_de_ligne(page) }
  Verify.check('Add') { ajouter(page, ctx) }
  Verify.check('Public page') { page_publique_inchangee(page, ctx) }
  Verify.check('Width') { largeurs(page, ctx[:demarche]) }
  Verify.check('Undo') { defaire(page, ctx) }
  Verify.check('Proof') { preuve(page, ctx) }
ensure
  nettoyer(ctx) if ctx
end
