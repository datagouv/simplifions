module Brouillonnable
  extend ActiveSupport::Concern

  included { after_destroy_commit { purger_les_fichiers(brouillon.to_h) } }

  class_methods do
    def changements_du_brouillon(version)
      publiee = version.reify(dup: true)
      champs = column_names - %w[id brouillon modifie_le created_at updated_at]
      avant, apres = version.changeset['brouillon'].map { publiee.dup.appliquer_brouillon(it.to_h.slice(*champs)) }
      champs.index_with { [avant.public_send(it), apres.public_send(it)] }.reject { |_, (ancien, nouveau)| ancien == nouveau }
    end
  end

  def brouillon? = brouillon.present?

  def date_du_brouillon = brouillon&.dig('modifie_le')&.to_time

  def passe_par_un_brouillon? = visible? || brouillon.to_h['visible'] == '1'

  def import_grist_depuis_le_brouillon
    debut = brouillon&.dig('commence_le')&.to_time
    versions.where(whodunnit: Grist::Import::AUTEUR, created_at: debut..).last if debut
  end

  def enregistrer(attributs, contexte: nil)
    attributs = attributs.to_h.stringify_keys
    return ecrire(attributs, contexte) unless passe_par_un_brouillon? && !publication_demandee?(attributs)

    return false unless enregistrer_brouillon(attributs.except('visible'), contexte)

    attributs['visible'] == '0' ? update(attributs.slice('visible', 'modifie_le')) : true
  end

  def appliquer_brouillon(attributs = brouillon)
    liaisons = self.class.reflect_on_all_associations(:has_and_belongs_to_many).index_by { "#{it.name.to_s.singularize}_ids" }
    sans_date_de_debut(attributs).each do |cle, valeur|
      liaison = liaisons[cle]
      liaison ? association(liaison.name).target = liaison.klass.where(id: valeur).to_a : public_send("#{cle}=", valeur)
    end
    self
  end

  def abandonner_brouillon!
    purger_les_fichiers(brouillon.to_h)
    ecrire_le_brouillon(nil, 'abandon')
  end

  private

  def publication_demandee?(attributs) = attributs.to_h.stringify_keys['visible'] == '1'

  def sans_date_de_debut(attributs) = attributs.to_h.except('commence_le')

  def ecrire(attributs, contexte = nil)
    remplaces = brouillon.to_h.slice(*attributs.keys)
    ecrits = sans_date_de_debut(brouillon).merge(attributs, 'brouillon' => nil)
    ecrit = avec_evenement(('publication' if publie_le_brouillon?(ecrits))) do
      with_transaction_returning_status do
        assign_attributes(ecrits)
        save(context: contexte)
      end
    end
    purger_les_fichiers(remplaces) if ecrit
    ecrit
  end

  def publie_le_brouillon?(ecrits) = brouillon? && self.class.type_for_attribute('visible').cast(ecrits.fetch('visible', visible))

  def enregistrer_brouillon(attributs, contexte = nil)
    return garder_la_saisie_sans_fichier(attributs) unless saisie_acceptee?(attributs, contexte)

    remplaces = brouillon.to_h.slice(*attributs.keys)
    attributs = { 'commence_le' => Time.current }.merge(brouillon.to_h, attributs.transform_values { en_valeur_de_brouillon(it) })
    ecrire_le_brouillon((attributs if differe_du_publie?(attributs)), 'brouillon')
    purger_les_fichiers(remplaces)
    true
  end

  def ecrire_le_brouillon(valeur, evenement)
    avec_evenement(evenement) { paper_trail.update_columns(brouillon: valeur) } unless valeur == brouillon
  end

  def avec_evenement(evenement)
    self.paper_trail_event = evenement
    yield
  ensure
    self.paper_trail_event = nil
  end

  def saisie_acceptee?(attributs, contexte)
    erreurs_bloquantes(attributs, contexte).each { errors.import(it) }
    errors.empty?
  end

  def erreurs_bloquantes(attributs, contexte)
    copie = copie_avec_le_brouillon(attributs)
    erreurs = copie.tap(&:validate).errors.objects.dup
    copie.validate(contexte) if contexte
    erreurs_sur_les_fichiers(erreurs, attributs) + (copie.errors.objects - erreurs)
  end

  def copie_avec_le_brouillon(attributs) = self.class.find(id).appliquer_brouillon(brouillon.to_h.merge(attributs))
  def erreurs_sur_les_fichiers(erreurs, attributs) = erreurs.select { fichiers_de(attributs).compact_blank.key?(it.attribute.to_s) }

  def garder_la_saisie_sans_fichier(attributs)
    appliquer_brouillon(brouillon.to_h.merge(attributs.except(*fichiers_de(attributs).keys)))
    false
  end

  def differe_du_publie?(attributs)
    copie = self.class.find(id).appliquer_brouillon(attributs)
    copie.changes.except('modifie_le').any? { |_, valeurs| valeurs.any?(&:present?) } || copie.attachment_changes.any? ||
      liaisons_changees?(copie, attributs.keys.grep(/_ids\z/))
  end

  def liaisons_changees?(copie, cles) = cles.any? { |cle| copie.public_send(cle).sort != public_send(cle).sort }

  def en_valeur_de_brouillon(valeur)
    return valeur.gsub("\r\n", "\n") if valeur.is_a?(String)
    return valeur unless valeur.is_a?(ActionDispatch::Http::UploadedFile)

    ActiveStorage::Blob.create_and_upload!(io: valeur, filename: valeur.original_filename, content_type: valeur.content_type).signed_id
  end

  def fichiers_de(attributs) = attributs.to_h.slice(*self.class.attachment_reflections.keys)

  def purger_les_fichiers(attributs)
    fichiers_de(attributs).each_value { ActiveStorage::Blob.find_signed(it)&.purge_later }
  end
end
