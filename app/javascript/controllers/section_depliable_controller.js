import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bouton", "contenu"]

  basculer() {
    this.deplier(this.boutonTarget.getAttribute("aria-expanded") !== "true")
  }

  appliquer({ detail: { deplie } }) {
    this.deplier(deplie)
  }

  deplier(deplie) {
    this.boutonTarget.setAttribute("aria-expanded", deplie)
    this.contenuTarget.hidden = !deplie
  }
}
