require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#markdown' do
    it 'rend le CommonMark en HTML' do
      html = helper.markdown("Du **gras** et [un lien](https://legifrance.gouv.fr)\n\n- une liste")

      expect(html).to include('<strong>gras</strong>')
      expect(html).to include('<a href="https://legifrance.gouv.fr">un lien</a>')
      expect(html).to include('<li>une liste</li>')
    end

    it 'neutralise le HTML brut et les URLs dangereuses' do
      html = helper.markdown("<script>alert(1)</script>\n\n[clic](javascript:alert(1))")

      expect(html).not_to include('<script>')
      expect(html).not_to include('javascript:')
    end

    it 'rend une chaîne vide pour un contenu absent' do
      expect(helper.markdown(nil)).to eq('')
    end
  end
end
