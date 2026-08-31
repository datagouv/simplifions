# Données des cartes citées dans les articles, figées en attendant le
# catalogue en base (SIM-9) : une seule définition par solution/démarche.
module ArticlesHelper
  SOLUTION_CARDS = {
    'bouquet-api-particulier' => { title: 'Bouquet API Particulier', href: '/solutions/bouquet-api-particulier', badge: 'Solution publique | DINUM', image: 'solutions/bouquet-api-particulier.png', usagers: ['Particuliers'], tag: 'Brique technique' },
    'bouquet-api-entreprise' => { title: 'Bouquet API Entreprise', href: '/solutions/bouquet-api-entreprise', badge: 'Solution publique | DINUM', image: 'solutions/bouquet-api-entreprise.png', usagers: %w[Entreprises Associations], tag: 'Brique technique' },
    'api-impot-particulier' => { title: 'API Impôt particulier', href: '/solutions/api-impot-particulier', badge: 'Solution publique | DGFIP', usagers: ['Particuliers'], tag: 'Brique technique' },
    'api-service-finances-publiques-sfip' => { title: 'API service finances publiques (SFIP)', href: '/solutions/api-service-finances-publiques-sfip', badge: 'Solution publique | DGFIP', usagers: ['Particuliers'], tag: 'Brique technique' },
    'franceconnect-2' => { title: 'FranceConnect', href: '/solutions/franceconnect-2', badge: 'Solution publique | DINUM', image: 'solutions/franceconnect-2.png', usagers: ['Particuliers'], tag: 'Brique technique' },
    'annuaire-des-entreprises' => { title: 'Annuaire des Entreprises', href: '/solutions/annuaire-des-entreprises', badge: 'Solution publique | DINUM', image: 'solutions/annuaire-des-entreprises.png', usagers: %w[Entreprises Associations], tag: 'Portail de consultation' },
    'data-subvention' => { title: 'Data.Subvention', href: '/solutions/data-subvention', badge: 'Solution publique | DINUM, DJEPVA', image: 'solutions/data-subvention.png', usagers: ['Associations'], tag: 'Portail de consultation' },
    'formulaire-de-collecte-du-quotient-familial' => { title: 'Formulaire de collecte du quotient familial', href: '/solutions/formulaire-de-collecte-du-quotient-familial', badge: 'Solution publique | DINUM', image: 'solutions/formulaire-de-collecte-du-quotient-familial.png', usagers: ['Particuliers'], tag: 'Brique technique' }
  }.freeze

  DEMARCHE_CARDS = {
    'marches-publics-depot-et-instruction-des-candidatures' => { title: '💼 Marchés publics | Dépôt et instruction des candidatures', href: '/cas-d-usages/marches-publics-depot-et-instruction-des-candidatures', usagers: %w[Associations Entreprises], acteurs: ['Tous les acteurs publics'] },
    'subventions-des-associations-attribution' => { title: '🎟️ Subventions des associations | Attribution', href: '/cas-d-usages/subventions-des-associations-attribution', usagers: ['Associations'], acteurs: ['Tous les acteurs publics'] },
    'tarification-cantine-scolaire-a-1-eur' => { title: '🥣 Tarification cantine scolaire à 1€', href: '/cas-d-usages/tarification-cantine-scolaire-a-1eur', usagers: ['Particuliers'], acteurs: ['Communes et groupements de communes'] },
    'tarification-sociale-municipale-a-lenfance' => { title: "👶 Tarification sociale des services municipaux à l'enfance", href: '/cas-d-usages/tarification-sociale-des-services-municipaux-a-lenfance', usagers: ['Particuliers'], acteurs: ['Communes et groupements de communes'] }
  }.freeze

  def solution_card(slug)
    SOLUTION_CARDS.fetch(slug)
  end

  def demarche_card(slug)
    DEMARCHE_CARDS.fetch(slug)
  end
end
