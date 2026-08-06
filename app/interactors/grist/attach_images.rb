require 'net/http'

class Grist::AttachImages < Grist::ImportStep
  def call
    each_record('Solutions') do |gid, fields|
      solution = context.index[gid] || next
      attachment_id = list(fields['Image']).first || next
      next if solution.image.attached?

      attach(gid, solution, attachment_id)
    end
  end

  private

  def attach(gid, solution, attachment_id)
    response = Net::HTTP.get_response(URI("#{Grist::FetchTables::DOC_URL}/attachments/#{attachment_id}/download"))
    return quarantine(gid, "image #{attachment_id} : HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    filename = response['Content-Disposition'].to_s[/filename="([^"]+)"/, 1] || "image-#{attachment_id}"
    solution.image.attach(io: StringIO.new(response.body), filename:, content_type: response['Content-Type'])
  end
end
