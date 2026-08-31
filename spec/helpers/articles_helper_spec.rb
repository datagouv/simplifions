require 'rails_helper'

RSpec.describe ArticlesHelper do
  describe 'DEMARCHE_CARDS' do
    it 'ne pointe que vers des slugs publiés du snapshot topics' do
      slugs_publies = Grist::ImportStep::SNAPSHOT.values.pluck('slug')

      described_class::DEMARCHE_CARDS.each_value do |card|
        slug = card[:href].delete_prefix('/cas-d-usages/')
        expect(slugs_publies).to include(slug), "slug périmé : #{card[:href]}"
      end
    end
  end
end
