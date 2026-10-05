require 'capybara'
require 'selenium-webdriver'
require 'tmpdir'

module Verify
  PORT = ENV.fetch('VERIFY_PORT', '3101')
  HOST = "http://localhost:#{PORT}".freeze
  ROOT = Rails.root.join('tmp/verify')
  ADMIN = { email: 'verif@simplifions.local', password: 'verif-simplifions-2026' }.freeze
  FIREFOX = ENV.fetch('VERIFY_FIREFOX', File.expand_path('~/.cache/simplifions-verify/firefox/firefox'))
  GECKODRIVER = Dir[File.expand_path('~/.cache/selenium/geckodriver/linux64/*/geckodriver')].max

  Capybara.register_driver :verify_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    %W[--headless=new --no-sandbox --disable-dev-shm-usage --remote-debugging-pipe --window-size=1280,1024
       --lang=fr-FR --user-data-dir=#{Dir.mktmpdir('verify-chrome')}].each { |flag| options.add_argument(flag) }
    Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
  end

  Capybara.register_driver :verify_firefox do |app|
    options = Selenium::WebDriver::Firefox::Options.new(binary: FIREFOX)
    options.add_argument('-headless')
    options.add_argument('--width=1280')
    options.add_argument('--height=1024')
    options.add_preference('intl.accept_languages', 'fr-FR,fr')
    service = Selenium::WebDriver::Service.firefox(path: GECKODRIVER)
    Capybara::Selenium::Driver.new(app, browser: :firefox, options:, service:)
  end

  def self.browser = ENV.fetch('VERIFY_BROWSER', 'chrome')

  def self.session
    Capybara.run_server = false
    Capybara.app_host = HOST
    Capybara.default_max_wait_time = 5
    Capybara::Session.new(:"verify_#{browser}")
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
end
