import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["publiques", "vide", "cartes", "tableau", "tri", "liste"]

  connect() {
    const vue = this.element.querySelector('input[name="affichage-solutions"]:checked')
    this.montrer(vue ? vue.value : "cartes")
    this.filtrer()
  }

  afficher(event) {
    this.montrer(event.target.value)
  }

  montrer(vue) {
    this.cartesTargets.forEach((cartes) => cartes.classList.toggle("fr-hidden", vue !== "cartes"))
    this.tableauTargets.forEach((tableau) => tableau.classList.toggle("fr-hidden", vue !== "tableau"))
  }

  trier() {
    const parNom = this.triTarget.value === "titre"
    const comparer = (a, b) => parNom ?
      a.dataset.nom.localeCompare(b.dataset.nom, "fr") :
      Number(a.dataset.ordre) - Number(b.dataset.ordre)
    this.listeTargets.forEach((liste) => liste.append(...[...liste.children].sort(comparer)))
  }

  filtrer() {
    const publiquesSeules = this.publiquesTarget.checked
    let total = 0
    this.element.querySelectorAll("details[data-categorie]").forEach((bloc) => {
      const solutions = bloc.querySelectorAll("[data-privee]")
      solutions.forEach((solution) => solution.classList.toggle("fr-hidden", publiquesSeules && solution.dataset.privee === "true"))
      const visibles = bloc.querySelectorAll("li[data-privee]:not(.fr-hidden)").length
      const badge = bloc.querySelector("[data-compte]")
      badge.textContent = `${visibles} ${visibles > 1 ? badge.dataset.pluriel : badge.dataset.singulier}`
      bloc.classList.toggle("fr-hidden", visibles === 0)
      total += visibles
    })
    this.videTarget.classList.toggle("fr-hidden", total > 0)
  }
}
