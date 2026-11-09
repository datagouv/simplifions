module FiltresHelper
  def valeur_de_filtre(options, valeurs) = options.map(&:last).intersection(valeurs).join(',')
end
