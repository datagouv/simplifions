require 'rails_helper'

RSpec.describe Organisation do
  it 'accepte « Public », « Privé » et le vide, refuse une autre casse' do
    [nil, '', 'Public', 'Privé'].each do |valeur|
      expect(described_class.new(nom: 'DINUM', public_ou_prive: valeur)).to be_valid
    end
    organisation = described_class.new(nom: 'DINUM', public_ou_prive: 'public')
    expect(organisation).not_to be_valid
    expect(organisation.errors.full_messages).to eq(['Public ou prive doit être choisi dans la liste'])
  end
end
