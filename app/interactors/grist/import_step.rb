require 'net/http'

class Grist::ImportStep < ApplicationInteractor
  DOC_URL = 'https://grist.numerique.gouv.fr/api/docs/ofSVjCSAnMb6'.freeze
  SNAPSHOT = JSON.parse(Rails.root.join('db/grist/topics_snapshot.json').read).freeze

  private

  def grist_get(path)
    Net::HTTP.get_response(URI("#{DOC_URL}/#{path}"))
  end

  def each_record(table)
    context.tables.fetch(table).each { |record| yield "#{table}:#{record['id']}", record['fields'] }
  end

  def synchronise(model, gid, attributes, also_by: nil)
    row = model.find_by(grist_id: gid) || (also_by && model.find_by(also_by)) || model.new
    row.grist_id = gid
    row.assign_attributes(attributes)
    assign_slug(row, gid) if row.respond_to?(:slug) && row.slug.blank?
    row.save!
    context.index[gid] = row
    row
  end

  def assign_slug(row, gid)
    slug = SNAPSHOT[gid] || row.nom.parameterize
    slug = "#{slug}-#{gid.split(':').last}" if row.class.where(slug:).where.not(id: row.id).exists?
    row.slug = slug
  end

  def find(table, ref, gid)
    row = ref.to_i.positive? && context.index["#{table}:#{ref}"]
    return row if row

    quarantine(gid, "référence #{table}:#{ref} introuvable")
    nil
  end

  def ids(table, reflist)
    list(reflist).filter_map do |ref|
      row = context.index["#{table}:#{ref}"]
      note("référence #{table}:#{ref} ignorée") unless row
      row&.id
    end
  end

  def list(value)
    value.is_a?(Array) ? value.drop(1) : []
  end

  def quarantine(gid, reason)
    context.report[:quarantine] << "#{gid} — #{reason}"
  end

  def note(message)
    context.report[:notes] << message
  end

  def time_at(epoch)
    epoch && Time.zone.at(epoch)
  end
end
