module Brouillonnable
  extend ActiveSupport::Concern

  included { after_destroy_commit { purger_les_fichiers(brouillon.to_h) } }

  def brouillon? = brouillon.present?

  def date_du_brouillon = brouillon&.dig('modifie_le')&.to_time

  def enregistrer(attributs)
    attributs = attributs.to_h.stringify_keys
    return ecrire(attributs) unless visible? && attributs['visible'] != '1'

    enregistrer_brouillon(attributs.except('visible'))
    attributs['visible'] == '0' ? update(attributs.slice('visible', 'modifie_le')) : true
  end

  def appliquer_brouillon(attributs = brouillon)
    liaisons = self.class.reflect_on_all_associations(:has_and_belongs_to_many).index_by { "#{it.name.to_s.singularize}_ids" }
    attributs.to_h.each do |cle, valeur|
      liaison = liaisons[cle]
      liaison ? association(liaison.name).target = liaison.klass.where(id: valeur).to_a : public_send("#{cle}=", valeur)
    end
    self
  end

  def abandonner_brouillon!
    purger_les_fichiers(brouillon.to_h)
    update_column(:brouillon, nil)
  end

  private

  def ecrire(attributs)
    remplaces = brouillon.to_h.slice(*attributs.keys)
    update(brouillon.to_h.merge(attributs, 'brouillon' => nil)).tap { purger_les_fichiers(remplaces) if it }
  end

  def enregistrer_brouillon(attributs)
    remplaces = brouillon.to_h.slice(*attributs.keys)
    attributs = brouillon.to_h.merge(attributs.transform_values { en_valeur_de_brouillon(it) })
    update_column(:brouillon, (attributs if differe_du_publie?(attributs)))
    purger_les_fichiers(remplaces)
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

  def purger_les_fichiers(attributs)
    attributs.slice(*self.class.attachment_reflections.keys).each_value { ActiveStorage::Blob.find_signed(it)&.purge_later }
  end
end
