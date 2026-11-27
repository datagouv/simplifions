import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["liste", "tableau"]
  static values = { tableauUtile: Boolean }

  connect() {
    if (this.tableauUtileValue && matchMedia("(min-width: 48em)").matches) this.tableauTarget.checked = true
  }

  trier({ target: { value } }) {
    const comparer = value === "titre" ?
      (a, b) => a.dataset.nom.localeCompare(b.dataset.nom, "fr", { sensitivity: "base" }) :
      (a, b) => Number(a.dataset.ordre) - Number(b.dataset.ordre)
    this.listeTargets.forEach((liste) => liste.append(...[...liste.children].sort(comparer)))
  }
}
