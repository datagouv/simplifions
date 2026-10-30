require_relative '../harness'

def contact_objet(page) = page.find('#objet-message').text

def depuis_la_fiche(page, demarche)
  page.visit("/demarches/#{demarche.slug}")
  lien = page.find_link('proposer vos modifications de cette démarche')
  raise "lien hors nouvel onglet : #{lien[:target]}" unless lien[:target] == '_blank'

  page.visit(lien[:href])
  page.assert_current_path("/contact/modifier-cas-usage?demarche=#{demarche.slug}")
end

def fiche_citee(page, demarche)
  raise 'démarche non présélectionnée' unless page.has_select?('Démarche concernée', selected: demarche.titre)
  raise "objet sans la fiche : #{contact_objet(page)}" unless contact_objet(page).end_with?(" : #{demarche.titre}")

  mailto = URI.decode_www_form_component(page.find_link('Ouvrir un e-mail déjà pré-rempli')[:href])
  raise "mailto sans la fiche : #{mailto}" unless mailto.include?("Fiche concernée : #{demarche.titre}")
end

def copie(page, demarche)
  page.driver.browser.add_permission('clipboard-write', 'granted') if Verify.browser == 'chrome'
  ["Copier l'e-mail", "Copier l'objet", 'Copier le modèle'].each { page.assert_selector :button, it }
  page.click_button "Copier l'objet"
  page.assert_selector '[data-copier-target=statut]', text: 'Objet du mail copié', visible: :all
  Verify.evidence('contact', page, 'fiche-citee', "slug=#{demarche.slug} objet=#{contact_objet(page)} copie=ok")
end

def autre_demarche_sans_recharger(page, autre)
  page.execute_script('window.verifSansRecharger = true')
  choisir(page, autre)
  raise 'page rechargée' unless page.evaluate_script('window.verifSansRecharger')

  Verify.evidence('contact', page, 'demarche-changee', "slug=#{autre.slug} objet=#{contact_objet(page)} sans_recharger=true")
end

def choisir(page, demarche)
  page.select demarche.titre, from: 'Démarche concernée'
  page.assert_current_path("/contact/modifier-cas-usage?demarche=#{demarche.slug}")
  page.assert_selector '#objet-message', text: " : #{demarche.titre}"
end

def retour_aux_contenus(page)
  page.click_link 'Retour'
  page.assert_current_path('/contact/contenu')
end

def choisie_sans_fiche(page, demarche)
  retour_aux_contenus(page)
  page.assert_selector 'h3', text: 'Démarches'
  page.click_link "Proposer une modification d'une démarche existante"
  raise "objet cité sans fiche : #{contact_objet(page)}" if contact_objet(page).include?(' : ')

  choisir(page, demarche)
  Verify.evidence('contact', page, 'demarche-choisie', "slug=#{demarche.slug} objet=#{contact_objet(page)}")
  retour_aux_contenus(page)
end

def reponse_sans_adresse(page)
  page.click_link 'Retour'
  page.assert_current_path('/contact')
  page.click_link "J'ai une question sur ma propre démarche administrative"
  page.assert_text 'Nous ne sommes pas en mesure de vous aider à ce sujet.'
  raise 'adresse donnée sans contact' if page.find('section', text: 'Nous ne sommes pas').has_css?('a[href^="mailto:"]', wait: 0)
end

Verify.drive(__FILE__) do |page|
  demarche, autre = Demarche.visibles.order(:nom).first(2)

  Verify.check('From a fiche') { depuis_la_fiche(page, demarche) }
  Verify.check('Fiche cited') { fiche_citee(page, demarche) }
  Verify.check('Copy') { copie(page, demarche) }
  Verify.check('Another démarche, no reload') { autre_demarche_sans_recharger(page, autre) }
  Verify.check('Chosen without a fiche') { choisie_sans_fiche(page, demarche) }
  Verify.check('No-contact answer') { reponse_sans_adresse(page) }
  Verify.check('Proof') { Verify.evidence('contact', page, 'reponse-sans-adresse', "path=#{page.current_path} mailto=0") }
end
