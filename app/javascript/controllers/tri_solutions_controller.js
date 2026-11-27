import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["liste", "tableau"]
  static values = { tableauUtile: Boolean }

  connect() {
    if (this.tableauUtileValue && matchMedia("(min-width: 48em)").matches) this.tableauTarget.checked = true
  }

  comparer(event) {
    event.preventDefault()
    this.tableauTarget.checked = true
    const solutions = document.getElementById("solutions-integratrices")
    window.dsfr(event.currentTarget.closest("dialog")).modal.conceal()
    window.dsfr(solutions).tabPanel.disclose()
    requestAnimationFrame(() => solutions.focus())
  }

  trier({ target: { value } }) {
    const comparer = value === "titre" ?
      (a, b) => a.dataset.nom.localeCompare(b.dataset.nom, "fr", { sensitivity: "base" }) :
      (a, b) => Number(a.dataset.ordre) - Number(b.dataset.ordre)
    this.listeTargets.forEach((liste) => liste.append(...[...liste.children].sort(comparer)))
  }
}
