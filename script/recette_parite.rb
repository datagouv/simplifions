#!/usr/bin/env ruby
# Recette de parité ancien site / nouveau site sur les pages du snapshot des topics.
#   bundle exec script/recette_parite.rb [--nouveau https://staging.simplifions.data.gouv.fr] [--seulement slug]... [--sortie tmp/recette/rapport.md]
require 'json'
require 'optparse'
require 'nokogiri'
require 'open3'
require 'selenium-webdriver'
require 'tmpdir'
require 'fileutils'

module RecetteParite
  ANCIEN = 'https://simplifions.data.gouv.fr'.freeze
  IGNORES = '[hidden], .api-or-dataset-header .fr-badge, .api-or-dataset-header .logo, .api-or-dataset-header .org-name, ' \
            '#tab-discussions, #tab-content-discussions, ' \
            '.dataservice-card .fr-badge, .dataservice-card img, .dataservice-card__org'.freeze
  FERMES = '.fr-accordion__btn[aria-expanded="false"]'.freeze
  BLOCS = 'p, li, h1, h2, h3, h4, h5, h6, div, section, article, tr, td, th, dt, dd, br, figcaption, a, button'.freeze
  MARQUE = "\u2029".freeze
  CHEMINS = { 'Cas_d_usages' => %w[cas-d-usages demarches], 'Solutions' => %w[solutions solutions] }.freeze

  module_function

  def texte(html)
    main = Nokogiri::HTML(html).at_css('main') or return []
    main.css(IGNORES).remove
    main.css(BLOCS).each { |bloc| bloc.add_previous_sibling(MARQUE) && bloc.add_next_sibling(MARQUE) }
    main.text.tr('’', "'").split(MARQUE).map { |ligne| ligne.gsub(/\s+/, ' ').strip }.reject(&:empty?)
  end

  def comparer(anciennes, nouvelles)
    Dir.mktmpdir do |dossier|
      fichiers = { 'ancien' => anciennes, 'nouveau' => nouvelles }.map { |nom, lignes| File.join(dossier, nom).tap { |f| File.write(f, "#{lignes.join("\n")}\n") } }
      sortie, = Open3.capture2('diff', *fichiers)
      sortie.lines.grep(/\A[<>] /).map { |ligne| ligne.chomp.sub(/\A[<>]/, '<' => '-', '>' => '+') }
    end
  end

  def urls(cle, slug, nouveau)
    ancien_chemin, nouveau_chemin = CHEMINS.fetch(cle.split(':').first)
    ["#{ANCIEN}/#{ancien_chemin}/#{slug}", "#{nouveau}/#{ancien_chemin}/#{slug}", "#{nouveau}/#{nouveau_chemin}/#{slug}"]
  end

  def statut(resultat)
    return "❌ #{resultat[:erreur]}" if resultat[:erreur]

    resultat[:diff].empty? ? '✅ identique' : "⚠️ #{resultat[:diff].size} lignes différentes"
  end

  def rapport(resultats, nouveau)
    lignes = ["# Recette de parité — #{Time.now.getlocal.strftime('%d/%m/%Y %H:%M')}", '',
              "Ancien : #{ANCIEN} — Nouveau : #{nouveau} — #{resultats.size} pages", '', '| Page | Statut |', '| -- | -- |']
    lignes += resultats.map { |r| "| [#{r[:slug]}](#{r[:nouvelle]}) | #{statut(r)} |" }
    resultats.select { |r| r[:diff].any? }.each { |r| lignes += ['', "### #{r[:slug]}", '', '```diff', *r[:diff], '```'] }
    "#{lignes.join("\n")}\n"
  end

  def visiter(navigateur, url)
    navigateur.navigate.to(url)
    Selenium::WebDriver::Wait.new(timeout: 20).until { navigateur.find_elements(css: 'main h1').any? { |h1| h1.text.strip != '' } }
    sleep 2
    deplier(navigateur)
    [texte(navigateur.page_source), navigateur.current_url]
  end

  def deplier(navigateur)
    3.times do
      fermes = navigateur.find_elements(css: FERMES)
      fermes.each { |bouton| navigateur.execute_script('arguments[0].click()', bouton) }
      fermes.empty? ? break : sleep(1)
    end
  end

  def recetter(cle, slug, nouveau, navigateur)
    ancienne, entree, nouvelle = urls(cle, slug, nouveau)
    resultat = { slug:, nouvelle:, diff: [], erreur: nil }
    anciennes, = visiter(navigateur, ancienne)
    nouvelles, arrivee = visiter(navigateur, entree)
    resultat[:erreur] = "redirigé vers #{arrivee} au lieu de #{nouvelle}" if arrivee.chomp('/') != nouvelle
    resultat.merge(diff: comparer(anciennes, nouvelles))
  rescue Selenium::WebDriver::Error::WebDriverError => e
    resultat.merge(erreur: e.message.lines.first.strip)
  end

  def navigateur
    options = Selenium::WebDriver::Chrome::Options.new
    %W[--headless=new --no-sandbox --disable-dev-shm-usage --remote-debugging-pipe
       --user-data-dir=#{File.expand_path('../tmp/recette/profil', __dir__)}].each { |arg| options.add_argument(arg) }
    Selenium::WebDriver.for(:chrome, options:).tap do |chrome|
      chrome.execute_cdp('Emulation.setLocaleOverride', locale: 'fr-FR')
      chrome.execute_cdp('Emulation.setUserAgentOverride', userAgent: chrome.execute_script('return navigator.userAgent'), acceptLanguage: 'fr-FR')
    end
  end

  def options(argv)
    options = { nouveau: 'https://staging.simplifions.data.gouv.fr', seulement: [], sortie: 'tmp/recette/rapport.md' }
    parseur = OptionParser.new
    parseur.on('--nouveau URL') { |url| options[:nouveau] = url.chomp('/') }
    parseur.on('--seulement SLUG') { |slug| options[:seulement] << slug }
    parseur.on('--sortie FICHIER') { |fichier| options[:sortie] = fichier }
    parseur.parse!(argv)
    options
  end

  def pages(options)
    snapshot = JSON.parse(File.read(File.expand_path('../db/grist/topics_snapshot.json', __dir__)))
    snapshot.select { |_, page| options[:seulement].empty? || options[:seulement].include?(page['slug']) }
  end

  def ecrire(resultats, options)
    FileUtils.mkdir_p(File.dirname(options[:sortie]))
    File.write(options[:sortie], rapport(resultats, options[:nouveau]))
    puts "#{resultats.count { |r| statut(r).start_with?('✅') }}/#{resultats.size} pages identiques — #{options[:sortie]}"
  end

  def lancer(argv)
    options = options(argv)
    pages = pages(options)
    chrome = navigateur
    resultats = pages.map.with_index(1) do |(cle, page), i|
      warn "#{i}/#{pages.size} #{page['slug']}"
      recetter(cle, page['slug'], options[:nouveau], chrome)
    end
    chrome.quit
    ecrire(resultats, options)
  end
end

RecetteParite.lancer(ARGV) if __FILE__ == $PROGRAM_NAME
