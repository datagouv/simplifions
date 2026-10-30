require_relative '../harness'

DOSSIER = 'mobile'.freeze
USAGERS = 'Démarches à destination des :'.freeze

def largeurs(page) = page.evaluate_script('[document.documentElement.scrollWidth, innerWidth]')

def sans_defilement_lateral!(page, endroit)
  page_large, fenetre = largeurs(page)
  raise "#{endroit} : page #{page_large} px pour une fenêtre de #{fenetre} px" if page_large > fenetre
end

def mobile_accueil(page)
  page.visit('/')
  bloc = page.find('h2', text: 'Ne demandez plus aux usagers').find(:xpath, '..')
  marge = -> { page.evaluate_script('getComputedStyle(arguments[0]).paddingLeft', bloc) }
  ordinateur = marge.call
  page.current_window.resize_to(320, 812)
  telephone = marge.call
  raise "marges #{telephone} / #{ordinateur}" unless telephone == '16px' && ordinateur == '80px'

  sans_defilement_lateral!(page, 'accueil')
  page.scroll_to(bloc, align: :top)
  Verify.evidence(DOSSIER, page, '1-accueil', "marge_telephone=#{telephone} marge_ordinateur=#{ordinateur} largeurs=#{largeurs(page)}")
end

def filtres_replies(page)
  page.visit('/demarches')
  bouton = page.find_button('Filtres', exact_text: true)
  page.assert_no_selector(:select, USAGERS)
  page.assert_selector(:field, 'Rechercher')
  page.assert_selector(:link, "Cas d'usages")
  sans_defilement_lateral!(page, 'catalogue')
  Verify.evidence(DOSSIER, page, '2-filtres-replies', "bouton=#{bouton.text.inspect} aria_expanded=#{bouton['aria-expanded']}")
  bouton
end

def ouvrir_et_appliquer(page, bouton)
  bouton.click
  page.select 'Entreprises', from: USAGERS
  Verify.evidence(DOSSIER, page, '3-filtres-ouverts', "aria_expanded=#{bouton['aria-expanded']}")
  page.click_button 'Appliquer les filtres'
  page.assert_current_path(/target-users=entreprises/, url: false)
  page.find_button('Filtres (1)', exact_text: true).tap { page.assert_no_selector(:select, USAGERS) }
end

def filtres_appliques(page, bouton)
  affiche = page.find('[role=status]').text[/\d+/].to_i
  attendu = Demarche.catalogue({ 'target-users' => 'entreprises' }).count
  raise "compte #{affiche} != base #{attendu}" unless affiche == attendu

  Verify.evidence(DOSSIER, page, '4-filtres-appliques',
    "bouton=#{bouton.text.inspect} aria_expanded=#{bouton['aria-expanded']} resultats=#{affiche} base=#{attendu}")
  bouton.click
  page.assert_selector(:select, USAGERS, selected: 'Entreprises')
  bouton.click
  page.assert_no_selector(:select, USAGERS)
end

def carte(page)
  page.evaluate_script(<<~JS, page.first('#list h3'))
    (titre => [getComputedStyle(titre).fontSize, getComputedStyle(titre.parentElement).padding,
               Math.round(titre.closest('li').getBoundingClientRect().height)])(arguments[0])
  JS
end

def mobile_cartes(page)
  titre, marge, hauteur = carte(page)
  raise "carte : titre #{titre}, marge #{marge}" unless titre == '18px' && marge == '12px'

  page.scroll_to(page.first('#list h3'), align: :top)
  Verify.evidence(DOSSIER, page, '5-cartes', "titre=#{titre} marge=#{marge} hauteur_premiere_carte=#{hauteur}")
end

def retrait_citation(page, citation)
  page.evaluate_script(<<~JS, citation)
    (citation => {
      const carte = citation.closest('div[id]')
      const style = getComputedStyle(carte)
      const debutCarte = carte.getBoundingClientRect().left + parseFloat(style.borderLeftWidth) + parseFloat(style.paddingLeft)
      const debutTexte = citation.getBoundingClientRect().left + citation.clientLeft + parseFloat(getComputedStyle(citation).paddingLeft)
      return [Math.round(debutTexte - debutCarte), Math.round(citation.getBoundingClientRect().right - debutTexte)]
    })(arguments[0])
  JS
end

def demarche_avec_citation = Demarche.visibles.find { |d| d.recommandations.visibles.any? { it.parametres_a_saisir.to_s.match?(/^>/) } }

def mobile_fiche(page)
  demarche = demarche_avec_citation
  page.visit("/demarches/#{demarche.slug}")
  citation = page.first('#donnees-disponibles blockquote')
  retrait, largeur = retrait_citation(page, citation)
  raise "citation à #{retrait} px du bord de la carte" if retrait > 40

  sans_defilement_lateral!(page, 'fiche')
  page.scroll_to(citation, align: :center)
  Verify.evidence(DOSSIER, page, '6-fiche', "slug=#{demarche.slug} retrait_citation=#{retrait} largeur_texte_citation=#{largeur}")
end

def position(page, bouton)
  page.evaluate_script('[Math.round(scrollY), Math.round(arguments[0].getBoundingClientRect().top), document.activeElement === arguments[0]]', bouton)
end

def accordeon_ouvert(page)
  bouton = page.find('#donnees-disponibles').first('button.fr-accordion__btn', text: 'Via un logiciel métier')
  page.scroll_to(bouton, align: :center)
  bouton.click
  page.assert_selector("##{bouton['aria-controls']}.fr-collapse--expanded")
  bouton
end

def mobile_accordeon(page)
  bouton = accordeon_ouvert(page)
  avant = position(page, bouton)
  bouton.click
  page.assert_selector("##{bouton['aria-controls']}", visible: :hidden)
  sleep 0.6
  apres = position(page, bouton)
  raise "fermeture : avant #{avant}, après #{apres}" unless apres == avant

  Verify.evidence(DOSSIER, page, '7-accordeon-ferme', "titre=#{bouton.text.squish.inspect} scroll_haut_focus_avant=#{avant} apres=#{apres}")
end

def mobile_ordinateur(page)
  page.current_window.resize_to(1280, 1024)
  page.visit('/demarches')
  page.assert_no_selector(:button, 'Filtres', exact_text: true)
  page.assert_selector(:select, USAGERS)
  page.assert_selector('p', text: 'Filtres', exact_text: true)
  titre, marge, = carte(page)
  raise "carte ordinateur : titre #{titre}, marge #{marge}" unless titre == '20px' && marge == '16px'

  Verify.evidence(DOSSIER, page, '8-ordinateur', "bouton=absent listes=visibles titre=#{titre} marge=#{marge}")
end

def mobile_filtres_sans_js
  page = Verify.session(javascript: false)
  page.visit('/demarches')
  page.current_window.resize_to(320, 812)
  page.assert_no_selector(:button, 'Filtres', exact_text: true)
  page.assert_selector(:select, USAGERS)
  Verify.evidence(DOSSIER, page, '9-filtres-sans-js', 'bouton=absent listes=visibles')
ensure
  page&.quit
end

Verify.drive(__FILE__) do |page|
  Verify.check('Home') { mobile_accueil(page) }
  bouton = Verify.check('Folded facets') { filtres_replies(page) }
  Verify.check('Open and apply') { filtres_appliques(page, ouvrir_et_appliquer(page, bouton)) }
  Verify.check('Cards') { mobile_cartes(page) }
  Verify.check('Fiche') { mobile_fiche(page) }
  Verify.check('Accordion') { mobile_accordeon(page) }
  Verify.check('Desktop') { mobile_ordinateur(page) }
  Verify.check('Without JavaScript') do
    page.quit
    mobile_filtres_sans_js
  end
  Verify.check('Proof') { Verify.captures_presentes(DOSSIER, %w[1-accueil 2-filtres-replies 3-filtres-ouverts 4-filtres-appliques 5-cartes 6-fiche 7-accordeon-ferme 8-ordinateur 9-filtres-sans-js]) }
end
