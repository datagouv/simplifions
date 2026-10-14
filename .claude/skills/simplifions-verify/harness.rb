require 'capybara'
require 'selenium-webdriver'
require 'socket'

module Verify
  PORT = 3101
  ROOT = Rails.root.join('tmp/verify')
  ADMIN = { email: 'verif@simplifions.local', password: 'verif-simplifions-2026' }.freeze
  CONTAINER_IP = Socket.ip_address_list.find(&:ipv4_private?).ip_address

  Capybara.register_driver :verify_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    %w[--headless=new --window-size=1280,1024 --lang=fr-FR].each { |flag| options.add_argument(flag) }
    Capybara::Selenium::Driver.new(app, browser: :remote, url: 'http://chrome:4444', options:)
  end

  Capybara.register_driver :verify_firefox do |app|
    options = Selenium::WebDriver::Firefox::Options.new
    %w[-headless --width=1280 --height=1024].each { |flag| options.add_argument(flag) }
    options.add_preference('intl.accept_languages', 'fr-FR,fr')
    Capybara::Selenium::Driver.new(app, browser: :remote, url: 'http://firefox:4444', options:)
  end

  def self.browser = ENV.fetch('VERIFY_BROWSER', 'chrome')

  def self.session
    Capybara.server = :puma, { Silent: true }
    Capybara.server_host = '0.0.0.0'
    Capybara.server_port = PORT
    Capybara.app_host = "http://#{CONTAINER_IP}:#{PORT}"
    Capybara.default_max_wait_time = 5
    Capybara::Session.new(:"verify_#{browser}", Rails.application)
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
