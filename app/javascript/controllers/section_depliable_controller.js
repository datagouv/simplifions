import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bouton", "contenu"]

  basculer() {
    const deplie = this.boutonTarget.getAttribute("aria-expanded") !== "true"
    this.boutonTarget.setAttribute("aria-expanded", deplie)
    this.contenuTarget.hidden = !deplie
  }
}
