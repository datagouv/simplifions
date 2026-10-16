import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cartes", "tableau", "tri", "liste"]

  connect() {
    const vue = this.element.querySelector('input[name="affichage-solutions"]:checked')
    this.montrer(vue ? vue.value : "cartes")
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
}
