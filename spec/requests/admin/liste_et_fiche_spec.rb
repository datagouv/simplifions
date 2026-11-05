require 'rails_helper'

RSpec.describe 'Liste à gauche de la fiche' do
  let(:admin) { Admin.create!(email: 'dorine@example.gouv.fr', password: 'mot-de-passe-solide') }
  let(:api_qf) { Solution.create!(nom: 'API QF', categorie: 'api') }
  let!(:aides) do
    Demarche.create!(nom: 'Aides', icone: '💧', slug: 'aides', visible: true).tap do |demarche|
      demarche.recommandations.create!(solution: api_qf, niveau: :niveau_1)
      demarche.recommandations.create!(solution: Solution.create!(nom: 'API Sirene', categorie: 'api'), niveau: :niveau_2)
    end
  end

  before do
    Demarche.create!(nom: 'Bourses', slug: 'bourses', visible: true, brouillon: { 'nom' => 'Bourses v2' })
    Demarche.create!(nom: 'Cantine')
    sign_in admin
  end

  def page = response.parsed_body
  def liste = page.at_css('nav[aria-label="Liste des démarches"]')
  def lignes = liste.css('li').map { it.text.squish }

  def noms(params = {})
    get('/admin/demarches', params:)
    liste.css('li a').map { it.at_css('.fr-text--bold').text.squish }
  end

  describe 'page Démarches' do
    it 'liste les démarches avec leur état et leur nombre de recommandations, et invite à en choisir une' do
      get '/admin/demarches'
      expect(lignes).to eq(['💧 Aides Publiée 2 recommandations', 'Bourses Publiée Brouillon 0 recommandations', 'Cantine Masquée 0 recommandations'])
      expect(liste.at_css('[role=status]').text.squish).to eq('3 démarches')
      expect(liste.css('a').find { it.text.squish == 'Ajouter une démarche' }['href']).to eq('/admin/demarches/new')
      expect(page.css('main').text.squish).to include('Choisissez une démarche dans la liste')
      expect(page.at_css('table')).to be_nil
      expect(liste.at_css('[aria-hidden=true]').text).to eq('💧')
    end

    it 'filtre la liste par état, avec la recherche' do
      expect(noms(etat: 'publiees')).to eq(['💧 Aides', 'Bourses'])
      expect(liste.css('select[name=etat] option').map(&:text)).to eq(['Toutes', 'Publiées', 'Masquées', 'En brouillon'])
      expect(liste.at_css('select[name=etat] option[selected]').text).to eq('Publiées')
      expect(noms(etat: 'masquees')).to eq(['Cantine'])
      expect(noms(etat: 'brouillons')).to eq(['Bourses'])
      expect(noms(etat: 'publiees', q: 'aides')).to eq(['💧 Aides'])
      expect(noms(etat: 'inconnu')).to eq(['💧 Aides', 'Bourses', 'Cantine'])
    end

    it 'dit qu’une recherche ne trouve rien et propose de l’effacer' do
      get '/admin/demarches', params: { q: 'introuvable', etat: 'publiees' }
      expect(liste.at_css('[role=status]').text.squish).to eq('Aucune démarche ne contient « introuvable ».')
      expect(liste.at_css('ul')).to be_nil
      expect(liste.css('a').find { it.text == 'Effacer la recherche' }['href']).to eq('/admin/demarches?etat=publiees')
    end
  end

  describe 'fiche d’une démarche' do
    it 'garde la liste à gauche avec la même recherche et le même filtre, la démarche ouverte signalée' do
      get '/admin/demarches', params: { q: 'aides', etat: 'publiees' }
      lien = liste.at_css('li a')['href']
      expect(lien).to eq("/admin/demarches/#{aides.id}/edit?etat=publiees&q=aides")

      get lien
      expect(liste.at_css('input[name=q]')['value']).to eq('aides')
      expect(liste.at_css('a[aria-current=page]')['href']).to eq(lien)
      expect(page.at_css('h1').text.squish).to eq('💧 Aides')
      expect(page.at_css('section[aria-label="État de la démarche"]')).to be_present
    end

    it 'garde la recherche et le filtre après l’enregistrement, la publication et à l’annulation' do
      get "/admin/demarches/#{aides.id}/edit", params: { q: 'aides', etat: 'publiees' }
      expect(page.css('input[form=formulaire-fiche][type=hidden]').to_h { [it['name'], it['value']] }).to eq('q' => 'aides', 'etat' => 'publiees')
      publier = page.css('form').find { it.at_css('button')&.text == 'Publier' }
      expect(publier.css('input[type=hidden]').to_h { [it['name'], it['value']] }).to include('q' => 'aides', 'etat' => 'publiees')

      get '/admin/demarches/new', params: { q: 'aides', etat: 'publiees' }
      expect(page.css('a').find { it.text == 'Annuler' }['href']).to eq('/admin/demarches?etat=publiees&q=aides')

      patch "/admin/demarches/#{aides.id}", params: { demarche: { nom: 'Aides locales' }, q: 'aides', etat: 'publiees' }
      expect(response).to redirect_to("/admin/demarches/#{aides.id}/edit?etat=publiees&q=aides")
    end

    it 'garde la liste à gauche sur l’ajout d’une démarche' do
      get '/admin/demarches/new'
      expect(lignes.size).to eq(3)
    end
  end
end
