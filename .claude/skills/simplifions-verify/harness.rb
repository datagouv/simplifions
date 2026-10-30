require 'capybara'
require 'selenium-webdriver'
require 'socket'

module Verify
  PORT = 3101
  ROOT = Rails.root.join('tmp/verify')
  ADMIN = { email: 'verif@simplifions.local', password: 'verif-simplifions-2026' }.freeze
  CONTAINER_IP = Socket.ip_address_list.find(&:ipv4_private?).ip_address

  def self.chrome(app, javascript: true)
    options = Selenium::WebDriver::Chrome::Options.new
    %w[--headless=new --window-size=1280,1024 --lang=fr-FR].each { |flag| options.add_argument(flag) }
    options.add_argument("--unsafely-treat-insecure-origin-as-secure=http://#{CONTAINER_IP}:#{PORT}")
    options.add_argument('--blink-settings=scriptEnabled=false') unless javascript
    Capybara::Selenium::Driver.new(app, browser: :remote, url: 'http://chrome:4444', options:)
  end

  def self.firefox(app, javascript: true)
    options = Selenium::WebDriver::Firefox::Options.new
    %w[-headless --width=1280 --height=1024].each { |flag| options.add_argument(flag) }
    options.add_preference('intl.accept_languages', 'fr-FR,fr')
    options.add_preference('dom.securecontext.allowlist', CONTAINER_IP)
    options.add_preference('javascript.enabled', false) unless javascript
    Capybara::Selenium::Driver.new(app, browser: :remote, url: 'http://firefox:4444', options:)
  end

  Capybara.register_driver(:verify_chrome) { chrome(it) }
  Capybara.register_driver(:verify_firefox) { firefox(it) }
  Capybara.register_driver(:verify_chrome_sans_js) { chrome(it, javascript: false) }
  Capybara.register_driver(:verify_firefox_sans_js) { firefox(it, javascript: false) }

  class Halt < StandardError; end

  def self.browser = ENV.fetch('VERIFY_BROWSER', 'chrome')

  def self.session(javascript: true)
    Capybara.server = :puma, { Silent: true }
    Capybara.server_host = '0.0.0.0'
    Capybara.server_port = PORT
    Capybara.app_host = "http://#{CONTAINER_IP}:#{PORT}"
    Capybara.default_max_wait_time = 5
    Capybara::Session.new(:"verify_#{browser}#{'_sans_js' unless javascript}", Rails.application).tap { (@sessions ||= []) << it }
  end

  def self.drive(file)
    @feature = File.basename(file, '.rb')
    @sessions = []
    ensure_admin
    yield @page = session
  rescue Halt
    nil
  rescue StandardError => e
    report_failure('outside a check', e)
  ensure
    @sessions.each(&:quit)
    puts "evidence tmp/verify/#{@feature}/"
  end

  def self.check(label)
    yield.tap { puts "PASS #{label}" }
  rescue Halt
    raise
  rescue StandardError => e
    report_failure(label, e)
    raise Halt
  end

  def self.report_failure(label, error)
    puts "FAIL #{label}: #{error.class} #{error.message.squish.truncate(400)}"
    evidence(@feature, @page, 'echec') if @page
  rescue StandardError
    nil
  end

  def self.ensure_admin
    Admin.find_or_create_by!(email: ADMIN[:email]) { |admin| admin.password = ADMIN[:password] }
  end

  def self.remove_admin = Admin.where(email: ADMIN[:email]).destroy_all

  def self.login(page)
    page.visit('/admin/connexion')
    return if page.current_path == '/admin'

    page.fill_in 'Adresse e-mail', with: ADMIN[:email]
    page.fill_in 'Mot de passe', with: ADMIN[:password]
    page.click_button 'Se connecter'
    page.assert_text 'Connecté.'
  end

  def self.logout(page)
    page.click_button 'Se déconnecter'
    page.assert_selector :link, 'Se connecter'
  end

  def self.evidence(feature, page, name, read_back = nil)
    dir = ROOT.join(feature)
    dir.mkpath
    page.save_screenshot(dir.join("#{browser}-#{name}.png").to_s)
    return unless read_back

    dir.join('read-back.txt').open('a') { |f| f.puts "#{Time.now.utc.iso8601} #{browser} #{name}: #{read_back}" }
  end

  module Etapes
    def rubrique(page, nom)
      lien = page.find("nav[aria-label='Menu de l’administration']").find_link(nom)
      chemin = URI(lien[:href]).path
      lien.click
      page.assert_current_path(chemin)
    end

    def rechercher(page, texte)
      page.fill_in 'Rechercher', with: texte
      page.click_button 'Rechercher'
      page.assert_current_path(/[?&]q=/, url: true)
    end

    def ouvrir_depuis_la_liste(page, nom)
      rechercher(page, nom)
      page.within('tbody') { page.click_link nom, exact_text: true }
    end

    def ouvrir_fiche(page, nom)
      rubrique(page, 'Démarches')
      ouvrir_depuis_la_liste(page, nom)
      page.find_field('Nom', with: nom)
    end

    def onglet(page, libelle)
      page.find('[role=tab]', text: /\A#{libelle}/).click
      page.assert_selector '[role=tab][aria-selected=true]', text: /\A#{libelle}/
    end

    def demande_avant_de_partir(page, question, &)
      message = page.dismiss_confirm(&)
      raise "confirmation #{message.inspect}" unless message == question
    end

    def titre_public(page, slug)
      page.visit("/demarches/#{slug}")
      page.find('h1').text.tap { page.visit('/admin') }
    end

    def captures_presentes(dossier, etapes)
      manquantes = etapes.reject { Verify::ROOT.join(dossier, "#{Verify.browser}-#{it}.png").exist? }
      raise "captures manquantes #{manquantes}" if manquantes.any?
    end

    def cases_affichees(groupe) = groupe.all('[data-liste-filtrable-target=element]:not(.fr-hidden) input', visible: :all)
    def liens_d_aide(zone) = zone.all('a:has(.fr-icon-question-line)').map { |lien| lien.text(:all).strip }
    def lien_nomme(zone, nom) = zone.all('a').find { |lien| (lien['aria-label'] || lien.text(:all).strip) == nom } || raise("aucun lien nommé #{nom}")
    def enregistrer_desactive?(page) = page.find('button[data-enregistrer]', visible: :all).disabled?
    def focus_sur(page) = page.evaluate_script('document.activeElement.id')
  end

  extend Etapes
end
