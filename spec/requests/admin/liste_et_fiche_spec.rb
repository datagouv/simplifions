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
  def invite = page.at_css('.liste-et-fiche__invite')
  def ajout_de_l_invite(texte) = invite.css('a').find { it.text.squish == texte }['href']

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
      expect(ajout_de_l_invite('Ajouter une démarche')).to eq('/admin/demarches/new')
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
      expect(noms(etat: 'publiees', q: 'aides')).to eq(['💧 Aides'])
      expect(ajout_de_l_invite('Ajouter une démarche')).to eq('/admin/demarches/new?etat=publiees&q=aides')
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
      expect(page.at_css('aside #etat-de-la-demarche')).to be_present
    end

    it 'garde la recherche et le filtre après l’enregistrement et la publication' do
      get "/admin/demarches/#{aides.id}/edit", params: { q: 'aides', etat: 'publiees' }
      expect(page.css('input[form=formulaire-fiche][type=hidden]').to_h { [it['name'], it['value']] }).to eq('q' => 'aides', 'etat' => 'publiees')
      expect(page.at_css('#etat-de-la-demarche button[form=formulaire-fiche][name="demarche[visible]"]').text).to eq('Masquer')

      patch "/admin/demarches/#{aides.id}", params: { demarche: { nom: 'Aides locales' }, q: 'aides', etat: 'publiees' }
      expect(response).to redirect_to("/admin/demarches/#{aides.id}/edit?etat=publiees&q=aides")
    end

    it 'garde la liste à gauche sur l’ajout d’une démarche' do
      get '/admin/demarches/new'
      expect(lignes.size).to eq(3)
    end
  end

  describe 'page Solutions' do
    def liste = page.at_css('nav[aria-label="Liste des solutions"]')

    def lignes_filtrees(params)
      get('/admin/solutions', params:)
      lignes
    end

    it 'liste les solutions avec leur catégorie et leur état, sans les démarches' do
      api_qf.update!(visible: true, brouillon: { 'nom' => 'API QF v2' })
      get '/admin/solutions'
      expect(lignes).to eq(['API QF API Publiée Brouillon', 'API Sirene API Masquée'])
      expect(liste.at_css('[role=status]').text.squish).to eq('2 solutions')
      expect(liste.css('a').find { it.text.squish == 'Ajouter une solution' }['href']).to eq('/admin/solutions/new')
      expect(page.css('main').text.squish).to include('Choisissez une solution dans la liste')
      expect(ajout_de_l_invite('Ajouter une solution')).to eq('/admin/solutions/new')
    end

    it 'filtre par état et garde la liste à gauche de la fiche, la solution ouverte signalée' do
      api_qf.update!(visible: true)
      get '/admin/solutions', params: { etat: 'masquees' }
      expect(lignes).to eq(['API Sirene API Masquée'])

      get liste.at_css('li a')['href']
      expect(liste.at_css('a[aria-current=page]').text.squish).to eq('API Sirene API Masquée')
      expect(liste.at_css('select[name=etat] option[selected]').text).to eq('Masquées')
      expect(page.at_css('h1').text).to eq('API Sirene (API)')
    end

    it 'filtre par catégorie de solution, avec l’état et la recherche, et garde le filtre sur la fiche' do
      Solution.create!(nom: 'API Cantine', categorie: 'brique_logicielle')
      Solution.create!(nom: 'API Bourses')
      api_qf.update!(visible: true)
      get '/admin/solutions', params: { categorie_filtree: 'api' }
      expect(lignes).to eq(['API QF API Publiée', 'API Sirene API Masquée'])
      expect(liste.css('select[name=categorie_filtree] option').map(&:text)).to eq(['Toutes', 'Brique technique', 'API', 'Jeu de données', 'Portail de consultation', 'Logiciel métier', 'Sans catégorie'])
      expect(liste.at_css('select[name=categorie_filtree] option[selected]').text).to eq('API')
      expect(lignes_filtrees(categorie_filtree: 'api', etat: 'masquees', q: 'sirene')).to eq(['API Sirene API Masquée'])
      expect(lignes_filtrees(categorie_filtree: 'sans_categorie')).to eq(['API Bourses Masquée'])
      expect(lignes_filtrees(categorie_filtree: 'inconnue').size).to eq(4)

      get '/admin/solutions', params: { categorie_filtree: 'brique_logicielle' }
      get liste.at_css('li a')['href']
      expect(lignes).to eq(['API Cantine Brique technique Masquée'])
      expect(liste.at_css('select[name=categorie_filtree] option[selected]').text).to eq('Brique technique')
    end

    it 'n’affiche pas le filtre par catégorie sur les démarches' do
      get '/admin/demarches'
      expect(page.at_css('select[name=categorie_filtree]')).to be_nil
    end

    it 'garde la recherche et le filtre après le choix de la catégorie' do
      get '/admin/solutions/new', params: { q: 'api', etat: 'masquees' }
      expect(page.at_css('form#formulaire-fiche')['action']).to eq('/admin/solutions/new')
      expect(page.css('input[form=formulaire-fiche][type=hidden]').to_h { [it['name'], it['value']] }).to eq('q' => 'api', 'etat' => 'masquees')
    end
  end
end
