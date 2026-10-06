require 'rails_helper'

RSpec.describe DsfrFormBuilder, type: :helper do
  def builder(objet) = described_class.new(objet.model_name.param_key, objet, helper, {})

  def rendu(html) = Nokogiri::HTML5.fragment(html)

  describe 'champ obligatoire' do
    it 'annonce un champ validé en présence, sans condition' do
      champ = rendu(builder(Demarche.new).dsfr_text_field(:nom))

      expect(champ.at_css('label').text).to eq('Nom (obligatoire)')
      expect(champ.at_css('input')['required']).not_to be_nil
    end

    it 'n’annonce pas un champ obligatoire seulement sous condition' do
      champ = rendu(builder(Demarche.new).dsfr_text_field(:slug))

      expect(champ.at_css('label').text).to start_with('Slug')
      expect(champ.at_css('label').text).not_to include('(obligatoire)')
      expect(champ.at_css('input')['required']).to be_nil
    end

    it 'annonce la liste d’une association obligatoire' do
      champ = rendu(builder(Recommandation.new).dsfr_select(:demarche_id, []))

      expect(champ.at_css('label').text).to eq('Démarche (obligatoire)')
    end
  end

  it 'reprend l’aide de activerecord.hints dans le libellé' do
    champ = rendu(builder(Demarche.new).dsfr_text_area(:contexte))

    expect(champ.at_css('label .fr-hint-text').text).to eq('Markdown accepté')
  end

  it 'signale l’erreur d’une association sous sa liste et la relie au champ' do
    recommandation = Recommandation.new.tap(&:validate)
    champ = rendu(builder(recommandation).dsfr_select(:demarche_id, []))

    expect(champ.at_css('.fr-select-group--error')).to be_present
    select = champ.at_css('select')
    expect(select['aria-invalid']).to eq('true')
    expect(champ.at_css("##{select['aria-describedby']}").text.strip).to eq('Choisissez une démarche')
  end

  it 'affiche sous la case à cocher l’erreur qu’elle annonce' do
    demarche = Demarche.new.tap { |objet| objet.errors.add(:visible, :blank) }
    champ = rendu(builder(demarche).dsfr_check_box(:visible))

    expect(champ.at_css("##{champ.at_css('input[type=checkbox]')['aria-describedby']}").text.strip).to eq('Visible sur simplifions doit être rempli')
  end

  it 'met une ligne par valeur d’une liste dans une zone de texte à la hauteur du contenu' do
    zone = rendu(builder(Demarche.new(mots_clefs: %w[cantine école])).dsfr_text_area(:mots_clefs)).at_css('textarea')

    expect(zone.text.strip).to eq("cantine\nécole")
    expect(zone['rows']).to eq('6')
  end
end
