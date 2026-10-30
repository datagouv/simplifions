require_relative '../harness'

Capybara.register_driver(:verify_chrome_souris) do |app|
  Verify.chrome(app).tap { it.options[:options].add_argument('--blink-settings=primaryPointerType=4,primaryHoverType=2') }
end

Capybara.register_driver(:verify_firefox_souris) do |app|
  Verify.firefox(app).tap { it.options[:options].add_preference('ui.primaryPointerCapabilities', 6) }
end

Capybara.register_driver(:verify_chrome_tactile) do |app|
  Verify.chrome(app).tap { it.options[:options].add_argument('--blink-settings=primaryPointerType=2,primaryHoverType=1') }
end

Capybara.register_driver(:verify_firefox_tactile) do |app|
  Verify.firefox(app).tap { it.options[:options].add_preference('ui.primaryPointerCapabilities', 1) }
end

def fonds(page, element)
  page.evaluate_script(<<~JS, element)
    (() => {
      const fonds = []
      for (let noeud = arguments[0]; noeud && fonds.length < 4; noeud = noeud.parentElement) {
        fonds.push(getComputedStyle(noeud).backgroundColor)
      }
      return fonds
    })()
  JS
end

def survoler(page, element)
  page.find('h1').hover
  avant = fonds(page, element)
  element.hover
  apres = fonds(page, element)
  { avant:, apres:, change: avant != apres }
end

def elements_survoles(page)
  carte = survoler(page, page.find('h3 a', match: :first))
  type = survoler(page, page.find(:link, text: /\ASolutions\s+\d+\z/))
  page.visit("/demarches/#{Demarche.visibles.order(:nom).first.slug}")
  bouton = survoler(page, page.find(:link, text: /Proposer une modification\s+- nouvelle fenêtre\z/))
  { carte:, type:, bouton: }
end

def appareil(page) = page.evaluate_script("matchMedia('(hover: hover) and (pointer: fine)').matches") ? 'souris' : 'tactile'

def verifier(page, appareil_emule)
  page.visit('/demarches')
  raise "appareil=#{appareil(page)}, attendu #{appareil_emule}" unless appareil(page) == appareil_emule

  survols = elements_survoles(page)
  ecarts = survols.reject { |_, survol| survol[:change] == (appareil_emule == 'souris') }
  raise "#{appareil_emule} : #{ecarts}" if ecarts.any?

  Verify.evidence('survol-souris', page, appareil_emule,
    "appareil=#{appareil_emule} #{survols.map { |nom, survol| "#{nom}=#{survol[:change] ? 'change' : 'inchange'}" }.join(' ')}")
end

Verify.drive(__FILE__) do |page|
  page.quit
  { 'souris' => 'Mouse', 'tactile' => 'Touch' }.each do |appareil_emule, label|
    session = Capybara::Session.new(:"verify_#{Verify.browser}_#{appareil_emule}", Rails.application)
    Verify.check(label) { verifier(session, appareil_emule) }
  ensure
    session&.quit
  end

  Verify.check('Proof') { Verify.captures_presentes('survol-souris', %w[souris tactile]) }
end
