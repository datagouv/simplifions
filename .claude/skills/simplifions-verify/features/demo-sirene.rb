require_relative '../harness'

Capybara.register_driver(:verify_chrome_animations_reduites) do |app|
  Verify.chrome(app).tap { it.options[:options].add_argument('--force-prefers-reduced-motion') }
end

Capybara.register_driver(:verify_firefox_animations_reduites) do |app|
  Verify.firefox(app).tap { it.options[:options].add_preference('ui.prefersReducedMotion', 1) }
end

def interroger_sans_reponse(page)
  page.visit('/articles/qu-est-ce-qu-une-api')
  page.execute_script('window.fetch = () => new Promise(() => {})')
  page.fill_in "Numéro de SIRET d'un établissement :", with: '35600000000048'
  page.click_button "Interroger l'API"
  page.scroll_to(page.find('p', text: "Interrogation de l'API en cours…"), align: :center)
end

def etat_de_l_icone(page)
  page.evaluate_script(<<~JS)
    (() => {
      const icone = document.querySelector('.sirene-demo__spinner')
      return {
        reduce: matchMedia('(prefers-reduced-motion: reduce)').matches,
        animation: getComputedStyle(icone).animationName,
        visible: icone.checkVisibility()
      }
    })()
  JS
end

def verifier_icone(page, etape, reduce:, animation:)
  etat = etat_de_l_icone(page)
  attendu = { 'reduce' => reduce, 'animation' => animation, 'visible' => true }
  raise "attendu #{attendu}, lu #{etat}" unless etat == attendu

  Verify.evidence('demo-sirene', page, etape, "reduce=#{etat['reduce']} animation=#{etat['animation']} icone=#{etat['visible']}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Turning') do
    interroger_sans_reponse(page)
    verifier_icone(page, 'icone-qui-tourne', reduce: false, animation: 'sirene-spin')
  end

  page.quit
  reduit = Capybara::Session.new(:"verify_#{Verify.browser}_animations_reduites", Rails.application)

  Verify.check('Still') do
    interroger_sans_reponse(reduit)
    verifier_icone(reduit, 'icone-immobile', reduce: true, animation: 'none')
  end

  Verify.check('Proof') do
    Verify.captures_presentes('demo-sirene', %w[icone-qui-tourne icone-immobile])
  end
ensure
  reduit&.quit
end
