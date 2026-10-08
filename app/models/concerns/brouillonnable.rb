module Brouillonnable
  extend ActiveSupport::Concern

  included { after_destroy_commit { purger_les_fichiers(brouillon.to_h) } }

  def brouillon? = brouillon.present?

  def date_du_brouillon = brouillon&.dig('modifie_le')&.to_time

  def passe_par_un_brouillon? = visible? || brouillon.to_h['visible'] == '1'

  def import_grist_depuis_le_brouillon
    debut = brouillon&.dig('commence_le')&.to_time
    versions.where(whodunnit: Grist::Import::AUTEUR, created_at: debut..).last if debut
  end

  def enregistrer(attributs)
    attributs = attributs.to_h.stringify_keys
    return ecrire(attributs) unless passe_par_un_brouillon? && !publication_demandee?(attributs)

    return false unless enregistrer_brouillon(attributs.except('visible'))

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
    update_column(:brouillon, nil)
  end

  private

  def publication_demandee?(attributs) = attributs.to_h.stringify_keys['visible'] == '1'

  def sans_date_de_debut(attributs) = attributs.to_h.except('commence_le')

  def ecrire(attributs)
    remplaces = brouillon.to_h.slice(*attributs.keys)
    update(sans_date_de_debut(brouillon).merge(attributs, 'brouillon' => nil)).tap { purger_les_fichiers(remplaces) if it }
  end

  def enregistrer_brouillon(attributs)
    return garder_la_saisie_sans_fichier(attributs) unless fichiers_acceptes?(attributs)

    remplaces = brouillon.to_h.slice(*attributs.keys)
    attributs = { 'commence_le' => Time.current }.merge(brouillon.to_h, attributs.transform_values { en_valeur_de_brouillon(it) })
    update_column(:brouillon, (attributs if differe_du_publie?(attributs)))
    purger_les_fichiers(remplaces)
    true
  end

  def fichiers_acceptes?(attributs)
    fichiers = fichiers_de(attributs).compact_blank
    return true if fichiers.empty?

    erreurs_avec_le_brouillon(attributs).each { errors.import(it) if fichiers.key?(it.attribute.to_s) }
    errors.empty?
  end

  def garder_la_saisie_sans_fichier(attributs)
    appliquer_brouillon(brouillon.to_h.merge(attributs.except(*fichiers_de(attributs).keys)))
    false
  end

  def erreurs_avec_le_brouillon(attributs) = self.class.find(id).appliquer_brouillon(brouillon.to_h.merge(attributs)).tap(&:validate).errors

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
