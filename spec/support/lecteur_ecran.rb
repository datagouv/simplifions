module LecteurEcran
  def lu_a_voix_haute(noeud)
    noeud.dup.tap { |copie| copie.css('[aria-hidden=true]').each(&:remove) }.text.squish
  end
end

RSpec.configure { |config| config.include LecteurEcran, type: :request }
