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

  it 'affiche la flèche sur demande' do
    render_inline(described_class.pour(solution, arrow: true))
    expect(page).to have_css('.card-arrow')
  end
end
