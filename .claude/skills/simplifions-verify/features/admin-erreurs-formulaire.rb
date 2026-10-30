require_relative '../harness'

DOSSIER = 'admin-erreurs-formulaire'.freeze
QUESTION = 'Quitter sans enregistrer les modifications ?'.freeze

def obligatoire(page)
  Verify.rubrique(page, 'Démarches')
  page.click_link 'Ajouter'
  raise 'Nom sans required' unless page.find_field('Nom (obligatoire)')[:required]
end

def liens_du_recapitulatif(recapitulatif)
  liens = recapitulatif.all('a').map { |lien| [lien[:href].split('#').last, lien.text] }
  liens.tap { raise "liens #{liens}" unless liens.map(&:first) == %w[demarche_nom demarche_slug] }
end

def recapitulatif(page, avant)
  page.click_button 'Publier'
  recapitulatif = page.find('.fr-alert--error', text: '2 erreurs à corriger')
  raise 'focus hors du récapitulatif' unless page.evaluate_script("document.activeElement.matches('.fr-alert--error')")

  liens = liens_du_recapitulatif(recapitulatif)
  Verify.evidence(DOSSIER, page, 'recapitulatif',
    "focus_recapitulatif=true liens=#{liens.map { it.join('=') }.join(' | ')} demarches_creees=#{Demarche.count - avant}")
  liens
end

def tabulation(page, liens)
  page.send_keys :tab
  page.evaluate_script('document.activeElement.textContent').tap do |premier|
    raise "Tab sur #{premier.inspect}" unless premier.strip == liens.first.last
  end
end

def lien_vers_le_champ(page)
  page.click_link 'Nom doit être rempli'
  page.evaluate_script('[location.hash, document.activeElement.id]').tap do |cible|
    raise "hash et focus #{cible}" unless cible == %w[#demarche_nom demarche_nom]
  end
end

def champ_en_erreur(page, premier, cible)
  champ = page.find_field('Nom (obligatoire)')
  message = page.find("##{champ['aria-describedby']}").text
  raise "aria-invalid=#{champ['aria-invalid']} message=#{message}" unless champ['aria-invalid'] == 'true' && message.include?('Nom doit être rempli')

  Verify.evidence(DOSSIER, page, 'champ', "tab=#{premier} hash=#{cible[0]} focus=#{cible[1]} aria_invalid=#{champ['aria-invalid']} message=#{message}")
end

def recommandation(page)
  page.visit('/admin/recommandations/new')
  page.click_button 'Publier'
  page.assert_text 'Choisissez une démarche'
  messages = page.all('.fr-select-group--error .fr-message--error').map(&:text)
  manquants = ['Choisissez une solution', 'Choisissez une démarche'].reject { |attendu| messages.any? { it.include?(attendu) } }
  raise "messages #{messages}" if manquants.any?

  Verify.evidence(DOSSIER, page, 'recommandation', "messages=#{messages.join(' | ')} recommandations_creees=0")
end

def etroit(page)
  page.current_window.resize_to(640, 1024)
  defilement = page.evaluate_script('document.documentElement.scrollWidth > innerWidth')
  Verify.evidence(DOSSIER, page, 'etroit', "defilement_horizontal=#{defilement}")
  page.current_window.resize_to(1280, 1024)
  raise 'défilement horizontal à 640 px' if defilement
end

def quitter(page)
  page.accept_confirm(QUESTION) { page.click_button 'Se déconnecter' }
  page.assert_selector :link, 'Se connecter'
end

Verify.drive(__FILE__) do |page|
  avant = Demarche.count
  Verify.login(page)
  Verify.check('Required') { obligatoire(page) }
  liens = Verify.check('Summary') { recapitulatif(page, avant) }
  premier = Verify.check('Keyboard') { tabulation(page, liens) }
  cible = Verify.check('Link') { lien_vers_le_champ(page) }
  Verify.check('Field') { champ_en_erreur(page, premier, cible) }
  Verify.check('Still changed') { Verify.demande_avant_de_partir(page, QUESTION) { page.click_link 'Annuler' } }
  Verify.check('Recommandation') { recommandation(page) }
  Verify.check('Narrow') { etroit(page) }
  Verify.check('Proof') { quitter(page) }
end
