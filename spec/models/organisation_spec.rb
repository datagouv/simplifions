require 'rails_helper'

RSpec.describe Organisation do
  it 'accepte « Public », « Privé » et le vide, refuse une autre casse' do
    [nil, '', 'Public', 'Privé'].each do |valeur|
      expect(described_class.new(nom: 'DINUM', public_ou_prive: valeur)).to be_valid
    end
    organisation = described_class.new(nom: 'DINUM', public_ou_prive: 'public')
    expect(organisation).not_to be_valid
    expect(organisation.errors.full_messages).to eq(['Public ou privé doit être choisi dans la liste'])
  end

  describe '#solutions_rendues_privees' do
    let(:dinum) { described_class.create!(nom: 'DINUM', public_ou_prive: 'Public') }
    let(:seule) { Solution.create!(nom: 'Seule', organisations: [dinum]) }
    let(:partagee) { Solution.create!(nom: 'Partagée', organisations: [dinum, described_class.create!(nom: 'ANCT', public_ou_prive: 'Public')]) }
    let(:avec_prive) { Solution.create!(nom: 'Avec privé', organisations: [dinum, described_class.create!(nom: 'Éditeur', public_ou_prive: 'Privé')]) }
    let(:api) { Solution.create!(nom: 'API QF', categorie: 'api', organisations: [dinum]) }

    it 'donne les fiches dont elle est le seul opérateur public' do
      [seule, partagee, avec_prive, api]
      expect(dinum.solutions_rendues_privees).to contain_exactly(seule, avec_prive)
    end

    it 'ne rend rien privé quand elle n’est pas publique' do
      editeur = described_class.create!(nom: 'Éditeur', public_ou_prive: 'Privé')
      Solution.create!(nom: 'Logiciel', organisations: [editeur])
      expect(editeur.solutions_rendues_privees).to be_empty
    end
  end
end
