require_relative '../harness'

DOSSIER = 'admin-image-refusee'.freeze
IMAGE = Rails.root.join('app/assets/images/articles/api-franceconnectees-donnees-personnelles.png').to_s

def envoyer_le_faux_png(page, solution, fichier)
  page.visit('/admin/solutions')
  Verify.ouvrir_depuis_la_liste(page, solution.nom)
  page.fill_in 'Nom', with: "#{solution.nom} renommée"
  page.attach_file('solution_image', fichier.to_s)
  page.click_button 'Enregistrer'
  page.assert_selector '.fr-upload-group', text: 'doit être une image png, jpg ou webp'
  page.find_field('Nom', with: "#{solution.nom} renommée")
end

def etat_en_base(solution, blobs)
  ActiveRecord::Base.uncached do
    lue = Solution.find(solution.id)
    [lue.nom, lue.image.attached?, lue.brouillon, ActiveStorage::Blob.count - blobs]
  end
end

def image_refusee_sur(page, solution, fichier)
  blobs = ActiveStorage::Blob.count
  envoyer_le_faux_png(page, solution, fichier)
  base = etat_en_base(solution, blobs)
  raise "refus #{solution.nom} : base #{base}" unless base == [solution.nom, false, nil, 0]

  Verify.evidence(DOSSIER, page, "refus-#{solution.visible? ? 'publiee' : 'masquee'}", "nom,image,brouillon,blobs_crees=#{base}")
end

def png_accepte(page, solution)
  page.attach_file('solution_image', IMAGE)
  page.click_button 'Enregistrer'
  page.assert_selector 'aside.admin-panneau', text: /Brouillon non publié/i
  image_en_brouillon = ActiveRecord::Base.uncached { solution.reload.brouillon.to_h.key?('image') }
  raise 'le brouillon ne contient pas l’image' unless image_en_brouillon

  Verify.evidence(DOSSIER, page, 'png-accepte', "brouillon_image=#{image_en_brouillon}")
end

Verify.drive(__FILE__) do |page|
  nom = "Vérif verify-map #{Verify.browser}"
  faux_png = Verify::ROOT.join('pdf-nomme.png').tap { it.dirname.mkpath }.tap { it.binwrite("%PDF-1.4\n") }
  Verify.login(page)
  solutions = [Solution.create!(nom: "#{nom} masquée"), Solution.create!(nom:, slug: "verif-verify-map-#{Verify.browser}", visible: true)]

  Verify.check('Refusal, hidden then published') { solutions.each { image_refusee_sur(page, it, faux_png) } }
  Verify.check('Accepted') { png_accepte(page, solutions.last) }
  Verify.check('Proof') { page.visit('/admin').then { Verify.logout(page) } }
ensure
  Solution.where(nom: ["#{nom} masquée", nom, "#{nom} masquée renommée", "#{nom} renommée"]).destroy_all
end
