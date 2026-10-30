require 'rails_helper'

RSpec.describe SolutionCardComponent, type: :component do
  let(:dinum) { Organisation.create!(nom: 'DINUM', public_ou_prive: 'Public') }
  let(:solution) do
    Solution.create!(nom: 'Bouquet API Particulier', slug: 'bouquet-api-particulier', organisations: [dinum],
      vocabulaires: [Vocabulaire.create!(nom: 'Particuliers', slug: 'particuliers', categorie: 'usager')])
  end

  it "affiche le titre, le badge opérateur en gras et l'audience" do
    render_inline(described_class.pour(solution))

    expect(page).to have_link('Bouquet API Particulier', href: '/solutions/bouquet-api-particulier')
    expect(page).to have_css('.fr-badge.fr-badge--blue-ecume b', text: 'DINUM')
    expect(page).to have_css('.fr-card__detail b', text: 'Particuliers')
    expect(page).to have_no_css('.card-arrow')
  end

  it 'affiche « Solution privée » en vert quand aucun opérateur n’est public' do
    editeur = Organisation.create!(nom: 'Éditeur', public_ou_prive: 'Privé')

    render_inline(described_class.pour(Solution.create!(nom: 'Logiciel', organisations: [editeur])))

    expect(page).to have_css('.fr-badge.fr-badge--green-tilleul-verveine', text: 'Solution privée | Éditeur')
  end

  it 'n’affiche pas de badge sans opérateur' do
    render_inline(described_class.pour(Solution.create!(nom: 'Sans opérateur')))
    expect(page).to have_no_css('.fr-grid-row')
  end

  it 'prépare pour Matomo l’ouverture d’une fiche dont le type de solution est une API, avec son origine' do
    solution.update!(types_solution: ['API'])
    render_inline(described_class.pour(solution, origine: 'article'))

    lien = page.find_link('Bouquet API Particulier')
    expect(lien['data-matomo-action']).to eq('Ouverture fiche solution API-jdd')
    expect(lien['data-matomo-nom']).to eq('Bouquet API Particulier [API, article]')
  end

  it 'ne mesure pas l’ouverture des autres fiches' do
    render_inline(described_class.pour(Solution.create!(nom: 'Logiciel', types_solution: ['Portail agent'])))

    expect(page.find_link('Logiciel')['data-matomo-action']).to be_nil
  end

  it 'affiche la flèche sur demande' do
    render_inline(described_class.pour(solution, arrow: true))
    expect(page).to have_css('.card-arrow')
  end
end
