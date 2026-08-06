require 'rails_helper'

RSpec.describe SolutionCardComponent, type: :component do
  let(:card) do
    { title: 'Bouquet API Particulier', href: '/solutions/bouquet-api-particulier',
      badge: 'Solution publique | DINUM', usagers: ['Particuliers'], tag: 'Brique technique' }
  end

  it "affiche le titre, le badge opérateur en gras et l'audience" do
    render_inline(described_class.new(card:))

    expect(page).to have_link('Bouquet API Particulier', href: '/solutions/bouquet-api-particulier')
    expect(page).to have_css('.fr-badge b', text: 'DINUM')
    expect(page).to have_css('.fr-card__detail b', text: 'Particuliers')
    expect(page).to have_no_css('.card-arrow')
  end

  it 'affiche la flèche sur demande' do
    render_inline(described_class.new(card:, arrow: true))
    expect(page).to have_css('.card-arrow')
  end
end
