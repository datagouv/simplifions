import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tag", "publiques", "vide", "cartes", "tableau"]

  connect() {
    this.observateur = new MutationObserver(() => this.filtrer())
    this.tagTargets.forEach((tag) => this.observateur.observe(tag, { attributeFilter: ["aria-pressed"] }))
    const vue = this.element.querySelector('input[name="affichage-solutions"]:checked')
    this.montrer(vue ? vue.value : "cartes")
    this.filtrer()
  }

  disconnect() {
    this.observateur.disconnect()
  }

  afficher(event) {
    this.montrer(event.target.value)
  }

  montrer(vue) {
    this.cartesTarget.classList.toggle("fr-hidden", vue !== "cartes")
    this.tableauTarget.classList.toggle("fr-hidden", vue !== "tableau")
  }

  filtrer() {
    const publiquesSeules = this.publiquesTarget.checked
    let total = 0
    this.tagTargets.forEach((tag) => {
      const categorie = tag.dataset.filtre
      const choisie = tag.getAttribute("aria-pressed") === "true"
      const cartes = [...this.element.querySelectorAll(`div[data-categorie="${categorie}"] li[data-privee]`)]
      cartes.forEach((carte) => carte.classList.toggle("fr-hidden", publiquesSeules && carte.dataset.privee === "true"))
      const visibles = cartes.filter((carte) => !carte.classList.contains("fr-hidden")).length
      this.element.querySelectorAll(`[data-compte="${categorie}"]`).forEach((compte) => { compte.textContent = visibles })
      this.element.querySelector(`div[data-categorie="${categorie}"]`).classList.toggle("fr-hidden", !choisie || visibles === 0)
      this.element.querySelectorAll(`tr[data-categorie="${categorie}"]`).forEach((ligne) => {
        ligne.classList.toggle("fr-hidden", !choisie || (publiquesSeules && ligne.dataset.privee === "true"))
      })
      if (choisie) total += visibles
    })
    this.videTarget.classList.toggle("fr-hidden", total > 0)
  }
}
