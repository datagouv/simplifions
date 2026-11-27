require_relative '../harness'

Verify.drive(__FILE__) do |page|
  Verify.check('Guard') do
    page.visit('/admin')
    page.assert_text 'Vous devez vous connecter pour accéder à cette page.'
  end

  Verify.check('Enter') do
    page.visit('/')
    raise 'bouton de connexion dans l’en-tête' if page.find('header').has_link?('Espace administrateur', wait: 0)

    page.find('footer').click_link 'Espace administrateur'
    page.assert_current_path('/admin/connexion')
    Verify.evidence('connexion-admin', page, 'entree-pied-de-page', "path=#{page.current_path}")
  end

  Verify.check('Log in') do
    Verify.login(page)
    page.assert_selector 'h1', text: 'Bonjour'
    page.assert_selector :link, 'Administration'
    raise 'lien du pied de page absent pour un admin' unless page.find('footer').find_link('Espace administrateur')[:href].end_with?('/admin')

    Verify.evidence('connexion-admin', page, 'tableau-de-bord', "path=#{page.current_path}")
  end

  Verify.check('Log out') do
    page.click_button 'Se déconnecter'
    page.assert_no_selector :button, 'Se déconnecter'
    page.visit('/admin')
    page.assert_current_path('/admin/connexion')
  end

  Verify.check('Proof') do
    Verify.evidence('connexion-admin', page, 'deconnecte', "path apres deconnexion=#{page.current_path}")
  end
end
