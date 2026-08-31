import { Controller } from "@hotwired/stimulus"

// Filtres, tri et compteurs de la section « Solutions intégrant … » d'une page solution.
export default class extends Controller {
  static targets = ["casUsage", "nbApis", "tri", "compteur", "vide", "onglet", "panneau", "carte"]

  filter() {
    const demarche = this.casUsageTarget.value
    const minimum = Number(this.nbApisTarget.value)

    this.carteTargets.forEach((carte) => {
      const demarches = (carte.dataset.demarches || "").split(" ")
      carte.hidden = (demarche && !demarches.includes(demarche)) || Number(carte.dataset.apis) < minimum
    })

    this.panneauTargets.forEach((panneau, index) => {
      this.trier(panneau)
      const visibles = this.carteTargets.filter((carte) => panneau.contains(carte) && !carte.hidden).length
      const onglet = this.ongletTargets[index]
      onglet.textContent = `${onglet.dataset.libelle} (${visibles})`
    })

    const total = this.carteTargets.filter((carte) => !carte.hidden).length
    this.compteurTarget.textContent = `${total} solution${total > 1 ? "s" : ""} disponible${total > 1 ? "s" : ""}`
    this.videTarget.hidden = total > 0
  }

  trier(panneau) {
    const parNom = this.triTarget.value === "titre"
    const cartes = this.carteTargets.filter((carte) => panneau.contains(carte))
    cartes.sort((a, b) => parNom ?
      a.dataset.nom.localeCompare(b.dataset.nom, "fr") :
      Number(b.dataset.apis) - Number(a.dataset.apis))
    panneau.append(...cartes)
  }
}
