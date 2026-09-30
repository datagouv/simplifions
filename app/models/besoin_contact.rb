BesoinContact = Data.define(:cle, :libelle, :description, :parent, :reponse, :liens, :a_verifier, :informations,
  :objet_mail, :fiche, :suite, :autres_sujets, :pictogramme, :groupe, :titre)

# Une étape du parcours de la page « Nous contacter », décrite dans config/contact.yml.
class BesoinContact
  # La fiche cas d'usage ou solution depuis laquelle l'usager est arrivé, citée dans le mail.
  Fiche = Data.define(:nom, :url)

  # Listes d'options référencées dans config/contact.yml, lues en base à chaque affichage
  # pour suivre le catalogue importé de Grist.
  OPTIONS = {
    'types_administrations' => -> { TypeActeur.order(:id).pluck(:nom) },
    'publics' => -> { Vocabulaire.categorie_usager.order(:id).pluck(:nom) }
  }.freeze

  # Une information à transmettre, éventuellement suivie de la liste des options possibles.
  Information = Data.define(:libelle, :liste) do
    def options
      liste ? OPTIONS.fetch(liste).call : []
    end

    def lignes_mail
      valeurs = options
      return ["#{libelle} :", ''] if valeurs.empty?

      ["#{libelle} (gardez les mentions utiles) :", *valeurs.map { |option| "- #{option}" }, '']
    end
  end

  def self.racines
    ALL.select { |besoin| besoin.parent.nil? }
  end

  def self.find(cle)
    ALL.find { |besoin| besoin.cle == cle }
  end

  def enfants
    ALL.select { |besoin| besoin.parent == cle }
  end

  def precedent
    self.class.find(parent)
  end

  # Les autres choix proposés à la même étape que ce besoin.
  def voisins
    (precedent ? precedent.enfants : self.class.racines) - [self]
  end

  # Une étape de choix propose ses enfants ; les autres étapes affichent une réponse ou le contact, sous un titre.
  def choix?
    enfants.any? && !contact? && suite.nil?
  end

  def titre
    to_h[:titre] || libelle
  end

  # L'adresse mail n'est donnée qu'aux étapes qui ont un objet de mail.
  def contact?
    objet_mail.present?
  end

  def objet_complet(fiche: nil)
    ["[Simplifions.data] #{objet_mail}", fiche&.nom].compact.join(' : ')
  end

  def corps_mail(fiche: nil)
    lignes = ['Bonjour,', '']
    lignes += ["Fiche concernée : #{fiche.nom} – #{fiche.url}", ''] if fiche
    lignes += informations.flat_map(&:lignes_mail)
    lignes += ['', 'Cordialement,']
    lignes.join("\n")
  end

  VALEURS_PAR_DEFAUT = { description: nil, parent: nil, reponse: [], liens: [], a_verifier: [], informations: [],
                         objet_mail: nil, fiche: nil, suite: nil, autres_sujets: false,
                         pictogramme: nil, groupe: nil,
                         titre: nil }.freeze

  def self.information(valeur)
    return Information.new(valeur, nil) if valeur.is_a?(String)

    liste = valeur.fetch(:options)
    OPTIONS.fetch(liste) # une liste inconnue dans config/contact.yml échoue dès le chargement
    Information.new(valeur.fetch(:libelle), liste)
  end

  ALL = YAML.load_file(Rails.root.join('config/contact.yml'))
    .map(&:deep_symbolize_keys)
    .map { |attrs| attrs.merge(informations: Array(attrs[:informations]).map { |valeur| information(valeur) }) }
    .map { |attrs| new(**VALEURS_PAR_DEFAUT, **attrs) }
    .freeze
end
