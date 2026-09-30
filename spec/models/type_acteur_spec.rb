require 'rails_helper'

RSpec.describe TypeActeur do
  describe '#slugs=' do
    it 'accepte une valeur par ligne, comme dans le formulaire d’administration' do
      expect(described_class.new(slugs: "communes\nregions").slugs).to eq(%w[communes regions])
    end
  end
end
