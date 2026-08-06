require 'net/http'

class Grist::ImportStep < ApplicationInteractor
  DOC_URL = 'https://grist.numerique.gouv.fr/api/docs/ofSVjCSAnMb6'.freeze
  SNAPSHOT = JSON.parse(Rails.root.join('db/grist/topics_snapshot.json').read).freeze
  NETWORK_ERRORS = [SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, EOFError].freeze

  private

  def grist_get(path)
    uri = URI("#{DOC_URL}/#{path}")
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      http.get(uri.request_uri)
    end
  end

  def each_record(table)
    context.tables.fetch(table).each { |record| yield "#{table}:#{record['id']}", record['fields'] }
  end

  def synchronise(model, gid, attributes, also_by: nil)
    row = resolve_row(model, gid, also_by)
    row.grist_id = gid
    row.assign_attributes(attributes)
    assign_slug(row, gid) if row.respond_to?(:slug) && row.slug.blank?
    row.save!
    context.index[gid] = row
    seen(row)
    row
  rescue ActiveRecord::RecordInvalid => e
    quarantine(gid, e.message)
    nil
  end

  def resolve_row(model, gid, also_by)
    model.find_by(grist_id: gid) || (also_by && model.find_by(also_by)) || model.new
  end

  def seen(row)
    context.seen[row.class.name] << row.id
  end

  def assign_slug(row, gid)
    slug = SNAPSHOT[gid] || row.nom.to_s.parameterize
    slug = "#{slug}-#{gid.split(':').last}" if row.class.where(slug:).where.not(id: row.id).exists?
    row.slug = slug
  end

  def find(table, ref, gid)
    unless ref.to_i.positive?
      quarantine(gid, "référence #{table} vide")
      return
    end

    row = context.index["#{table}:#{ref}"]
    quarantine(gid, "référence #{table}:#{ref} introuvable") unless row
    row
  end

  def ids(table, reflist, gid)
    list(reflist).filter_map do |ref|
      row = context.index["#{table}:#{ref}"]
      note("#{gid} — référence #{table}:#{ref} ignorée") unless row
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
