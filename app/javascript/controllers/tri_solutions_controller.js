import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["liste"]

  trier({ target: { value } }) {
    const comparer = value === "titre" ?
      (a, b) => a.dataset.nom.localeCompare(b.dataset.nom, "fr", { sensitivity: "base" }) :
      (a, b) => Number(a.dataset.ordre) - Number(b.dataset.ordre)
    this.listeTargets.forEach((liste) => liste.append(...[...liste.children].sort(comparer)))
  }
}
