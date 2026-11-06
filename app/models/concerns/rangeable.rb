module Rangeable
  def deplacer_a(position)
    voisines = rangees.reject { it.id == id }
    renumeroter(voisines.insert(position.clamp(1, voisines.size + 1) - 1, self))
  end

  def deplacer_d_un_rang(sens) = deplacer_a(rang + (sens == 'monter' ? -1 : 1))
  def rang = rangees.map(&:id).index(id).to_i + 1

  private

  def renumeroter(liste)
    transaction { liste.each.with_index(1) { |rangee, rang| rangee.ranger_a(rang) } }
    true
  end
end
