require_relative '../harness'

DEPOT_DIRECT = <<~JS.freeze
  const done = arguments[arguments.length - 1];
  fetch('/rails/active_storage/direct_uploads', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content },
    body: JSON.stringify({ blob: { filename: 'piege.png', byte_size: 3, checksum: 't5ir5uGxMY7jaw3LP7nk0w==', content_type: 'image/png' } })
  }).then(r => done(r.status)).catch(e => done(String(e)));
JS

def depot_direct_refuse(page, etape)
  avant = ActiveStorage::Blob.count
  statut = page.evaluate_async_script(DEPOT_DIRECT)
  crees = ActiveRecord::Base.uncached { ActiveStorage::Blob.count } - avant
  raise "#{etape} : statut #{statut}, fichiers créés #{crees}" unless statut == 404 && crees.zero?

  Verify.evidence('depot-direct-ferme', page, etape, "statut=#{statut} fichiers_crees=#{crees}")
end

Verify.drive(__FILE__) do |page|
  Verify.check('Visitor') do
    page.visit('/')
    depot_direct_refuse(page, 'visiteur')
  end

  Verify.check('Admin') do
    Verify.login(page)
    depot_direct_refuse(page, 'admin')
    Verify.logout(page)
  end

  Verify.check('Proof') do
    dossier = Verify::ROOT.join('depot-direct-ferme')
    manquantes = %w[visiteur admin].reject { dossier.join("#{Verify.browser}-#{it}.png").exist? }
    raise "captures manquantes #{manquantes}" if manquantes.any?
  end
end
