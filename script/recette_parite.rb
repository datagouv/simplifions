#!/usr/bin/env ruby
# Recette de parité ancien site / nouveau site sur les pages du snapshot des topics.
#   bundle exec script/recette_parite.rb [--nouveau https://staging.simplifions.data.gouv.fr] [--seulement slug]... [--sortie tmp/recette/rapport.md]
require 'json'
require 'optparse'
require 'nokogiri'
require 'diff/lcs'
require 'selenium-webdriver'
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
    main.css(BLOCS).each do |bloc|
      bloc.add_previous_sibling(MARQUE)
      bloc.add_next_sibling(MARQUE)
    end
    main.text.tr('’', "'").split(MARQUE).map { |ligne| ligne.gsub(/[[:space:]]+/, ' ').strip }.reject(&:empty?)
  end

  def comparer(anciennes, nouvelles)
    Diff::LCS.diff(anciennes, nouvelles).flatten(1).map { |changement| "#{changement.action} #{changement.element}" }
  end

  def urls(cle, slug, nouveau)
    ancien_chemin, nouveau_chemin = CHEMINS.fetch(cle.split(':').first)
    ["#{ANCIEN}/#{ancien_chemin}/#{slug}", "#{nouveau}/#{ancien_chemin}/#{slug}", "#{nouveau}/#{nouveau_chemin}/#{slug}"]
  end

  def identique?(resultat) = resultat[:erreur].nil? && resultat[:diff].empty?

  def statut(resultat)
    return "❌ #{resultat[:erreur]}" if resultat[:erreur]

    identique?(resultat) ? '✅ identique' : "⚠️ #{resultat[:diff].size} lignes différentes"
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
      break if fermes.empty?

      fermes.each { |bouton| navigateur.execute_script('arguments[0].click()', bouton) }
      sleep 0.5
    end
  end

  def recetter(cle, slug, nouveau, navigateur)
    ancienne, entree, nouvelle = urls(cle, slug, nouveau)
    anciennes, = visiter(navigateur, ancienne)
    nouvelles, arrivee = visiter(navigateur, entree)
    erreur = ("redirigé vers #{arrivee} au lieu de #{nouvelle}" if arrivee.chomp('/') != nouvelle)
    { slug:, nouvelle:, diff: comparer(anciennes, nouvelles), erreur: }
  rescue Selenium::WebDriver::Error::WebDriverError => e
    { slug:, nouvelle:, diff: [], erreur: e.message.lines.first.strip }
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
    choix = { nouveau: 'https://staging.simplifions.data.gouv.fr', seulement: [], sortie: 'tmp/recette/rapport.md' }
    parseur = OptionParser.new
    parseur.on('--nouveau URL') { |url| choix[:nouveau] = url.chomp('/') }
    parseur.on('--seulement SLUG') { |slug| choix[:seulement] << slug }
    parseur.on('--sortie FICHIER') { |fichier| choix[:sortie] = fichier }
    parseur.parse!(argv)
    choix
  end

  def pages(choix)
    snapshot = JSON.parse(File.read(File.expand_path('../db/grist/topics_snapshot.json', __dir__)))
    snapshot.select { |_, page| choix[:seulement].empty? || choix[:seulement].include?(page['slug']) }
  end

  def ecrire(resultats, choix)
    FileUtils.mkdir_p(File.dirname(choix[:sortie]))
    File.write(choix[:sortie], rapport(resultats, choix[:nouveau]))
    puts "#{resultats.count { |r| identique?(r) }}/#{resultats.size} pages identiques — #{choix[:sortie]}"
  end

  def lancer(argv)
    choix = options(argv)
    fiches = pages(choix)
    chrome = navigateur
    resultats = fiches.map.with_index(1) do |(cle, page), i|
      warn "#{i}/#{fiches.size} #{page['slug']}"
      recetter(cle, page['slug'], choix[:nouveau], chrome)
    end
    ecrire(resultats, choix)
  ensure
    chrome&.quit
  end
end

RecetteParite.lancer(ARGV) if __FILE__ == $PROGRAM_NAME
