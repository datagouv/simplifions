require_relative '../harness'

DOSSIER = 'titres-equilibres'.freeze
LARGEURS = [390, 1280].freeze

LIGNES = <<~JS.freeze
  [...document.querySelectorAll(arguments[0])].map(titre => {
    const lignes = []
    const walker = document.createTreeWalker(titre, NodeFilter.SHOW_TEXT)
    for (let noeud; (noeud = walker.nextNode());) {
      for (const mot of noeud.data.matchAll(/\\S+/g)) {
        const range = document.createRange()
        range.setStart(noeud, mot.index)
        range.setEnd(noeud, mot.index + mot[0].length)
        const top = Math.round(range.getBoundingClientRect().top)
        const ligne = lignes.find(it => Math.abs(it.top - top) < 4)
        ligne ? ligne.mots.push(mot[0]) : lignes.push({ top, mots: [mot[0]] })
      }
    }
    const style = getComputedStyle(titre)
    return { lignes: lignes.map(it => it.mots.join(' ')), coupure: style.textWrapStyle || style.textWrap }
  })
JS

def titres(page, selecteur) = page.evaluate_script(LIGNES, selecteur)

def capturer_a(page, largeur, nom, selecteur)
  tous = titres(page, selecteur)
  montre = tous.index(tous.select { it['lignes'].size == 2 }.max_by { it['lignes'].join.size }) || 0
  page.execute_script('document.querySelectorAll(arguments[0])[arguments[1]].scrollIntoView({ block: "center" })', selecteur, montre)
  Verify.evidence(DOSSIER, page, "#{nom}-#{largeur}", "#{nom} #{page.evaluate_script('innerWidth')}px #{tous[montre]['lignes'].map(&:inspect).join(' / ')}")
  tous
end

def capturer(page, nom, chemin, selecteur)
  LARGEURS.flat_map do |largeur|
    page.current_window.resize_to(largeur, 900)
    page.visit(chemin)
    capturer_a(page, largeur, nom, selecteur)
  end
end

Verify.drive(__FILE__) do |page|
  demarche = Demarche.visibles.where.not(slug: nil).max_by { it.titre.size }
  solution = Solution.visibles.where.not(slug: nil).max_by { it.nom.size }
  article = Article.all.max_by { it.h1.size }
  vus = []

  Verify.check('Catalogue cards') do
    vus += capturer(page, 'cartes-demarches', '/demarches', '#list h3')
    vus += capturer(page, 'cartes-solutions', '/solutions', '#list h3')
  end

  Verify.check('Page titles') do
    vus += capturer(page, 'fiche-demarche', "/demarches/#{demarche.slug}", 'h1')
    vus += capturer(page, 'fiche-solution', "/solutions/#{solution.slug}", 'h1')
    vus += capturer(page, 'article', "/articles/#{article.slug}", 'h1')
  end

  Verify.check('Proof') do
    autres = vus.map { it['coupure'] }.uniq - ['balance']
    raise "coupure #{autres} sur #{vus.size} titres" if autres.any?
  end
ensure
  page&.current_window&.resize_to(1280, 1024)
end
