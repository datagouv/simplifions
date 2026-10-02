require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#markdown' do
    it 'rend le CommonMark en HTML' do
      html = helper.markdown("Du **gras** et [un lien](https://legifrance.gouv.fr)\n\n- une liste")

      expect(html).to include('<strong>gras</strong>')
      expect(html).to include('<a href="https://legifrance.gouv.fr">un lien</a>')
      expect(html).to include('<li>une liste</li>')
    end

    it 'rend le HTML saisi dans le Grist avec ses classes DSFR' do
      html = helper.markdown(<<~MARKDOWN)
        <div class="fr-callout"><p class="fr-callout__title">Utilisez Comedec</p></div>

        <details><summary>En savoir plus</summary>Le détail</details>

        <hr>
      MARKDOWN

      expect(html).to include('<div class="fr-callout"><p class="fr-callout__title">Utilisez Comedec</p></div>')
      expect(html).to include('<details><summary>En savoir plus</summary>Le détail</details>')
      expect(html).to include('<hr>')
      expect(html).not_to include('raw HTML omitted')
    end

    it 'retire les scripts et les liens javascript:' do
      html = helper.markdown("<script>alert(1)</script>\n\n[clic](javascript:alert(1))")

      expect(html).not_to include('<script>')
      expect(html).not_to include('javascript:')
    end

    it 'retire les attributs de gestion d’événement et les liens data:' do
      html = helper.markdown(<<~MARKDOWN)
        <p onclick="alert(1)">Cliquez</p>

        <a href="data:text/html;base64,PHNjcmlwdD4=">lien</a>
      MARKDOWN

      expect(html).to include('Cliquez')
      expect(html).not_to include('onclick')
      expect(html).not_to include('data:')
    end

    it 'rend un tableau markdown' do
      html = helper.markdown("| API | Donnée |\n|---|---|\n| Comedec | Acte |")

      expect(html).to include('<th>API</th>')
      expect(html).to include('<td>Comedec</td>')
    end

    it 'rend un titre sans lien d’ancre vide' do
      html = helper.markdown("## Conditions d'accès")

      expect(html).to include("Conditions d'accès</h2>")
      expect(html).not_to include('<a ')
    end

    it 'rend une chaîne vide pour un contenu absent' do
      expect(helper.markdown(nil)).to eq('')
    end
  end
end
