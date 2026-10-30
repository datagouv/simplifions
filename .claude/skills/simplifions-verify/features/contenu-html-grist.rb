require_relative '../harness'

def avec_html(scope, *colonnes) = scope.where(colonnes.map { |colonne| "#{colonne} LIKE '%<%'" }.join(' OR '))

def demarches_avec_html
  recos = avec_html(Recommandation.where(visible: true), :donnees_utiles, :parametres_a_saisir, :description)
  (avec_html(Demarche.visibles, :contexte, :cadre_juridique).pluck(:slug) + Demarche.where(id: recos.select(:demarche_id)).pluck(:slug)).uniq
end

def pages_avec_html
  demarches_avec_html.map { "/demarches/#{it}" } +
    avec_html(Solution.visibles.fiches, :permet, :ne_permet_pas).pluck(:slug).map { "/solutions/#{it}" }
end

Verify.drive(__FILE__) do |page|
  Verify.check('Encadré') do
    page.visit('/demarches/actes-detat-civil')
    encadre = page.find('.fr-callout', text: 'Utilisez Comedec')
    encadre.scroll_to(encadre)
    Verify.evidence('contenu-html-grist', page, 'encadre-comedec', "encadre=#{encadre.tag_name}.fr-callout")
  end

  Verify.check('Séparateur') do
    page.visit('/solutions/passe-marche')
    separateur = page.find('hr:not([class])')
    separateur.scroll_to(separateur)
    Verify.evidence('contenu-html-grist', page, 'solution-hr', 'passe-marche hr_saisi=1')
  end

  chemins = Verify.check('Aucun HTML jeté') do
    pages_avec_html.tap do |chemins|
      omis = chemins.select do |chemin|
        page.visit(chemin)
        page.html.include?('raw HTML omitted')
      end
      raise "HTML omis sur #{omis.join(', ')}" if omis.any?
    end
  end

  Verify.check('Proof') do
    Verify.evidence('contenu-html-grist', page, 'aucun-html-omis', "pages_avec_html=#{chemins.size} omis=0")
  end
end
