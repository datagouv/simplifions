require_relative '../harness'

Verify.drive(__FILE__) do |page|
  Verify.check('Guard') do
    page.visit('/admin')
    page.assert_text 'Vous devez vous connecter pour accéder à cette page.'
  end

  Verify.check('Log in') do
    Verify.login(page)
    page.assert_selector 'h1', text: 'Administration'
    page.assert_selector :link, 'Administration'
    Verify.evidence('connexion-admin', page, 'tableau-de-bord', "path=#{page.current_path}")
  end

  Verify.check('Log out') do
    page.click_button 'Se déconnecter'
    page.assert_selector :link, 'Se connecter'
    page.visit('/admin')
    page.assert_current_path('/admin/connexion')
  end

  Verify.check('Proof') do
    Verify.evidence('connexion-admin', page, 'deconnecte', "path apres deconnexion=#{page.current_path}")
  end
end
