class Grist::AttachImages < Grist::ImportStep
  def call
    each_record('Solutions') do |gid, fields|
      solution = context.index[gid] || next
      attachment_id = list(fields['Image']).first || next
      next if deja_attachee?(solution, attachment_id)

      attach(gid, solution, attachment_id)
    end
  end

  private

  def deja_attachee?(solution, attachment_id)
    solution.image.attached? && solution.image.metadata['grist_attachment_id'] == attachment_id
  end

  def attach(gid, solution, attachment_id)
    response = grist_get("attachments/#{attachment_id}/download")
    return quarantine(gid, "image #{attachment_id} : HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    filename = response['Content-Disposition'].to_s[/filename="([^"]+)"/, 1] || "image-#{attachment_id}"
    solution.image.attach(io: StringIO.new(response.body), filename:, content_type: response['Content-Type'],
      metadata: { 'grist_attachment_id' => attachment_id })
  rescue *NETWORK_ERRORS => e
    quarantine(gid, "image #{attachment_id} : #{e.class} — #{e.message}")
  end
end
