import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["texte", "bouton"]

  connect() {
    if (this.texteTarget.scrollHeight > this.texteTarget.clientHeight) {
      this.boutonTarget.classList.remove("fr-hidden")
    } else {
      this.texteTarget.classList.remove("lire-plus--replie")
    }
  }

  basculer() {
    this.afficher(this.boutonTarget.getAttribute("aria-expanded") !== "true")
  }

  deplier() {
    if (!this.boutonTarget.classList.contains("fr-hidden")) this.afficher(true)
  }

  afficher(deplie) {
    this.texteTarget.classList.toggle("lire-plus--replie", !deplie)
    this.boutonTarget.setAttribute("aria-expanded", deplie)
    this.boutonTarget.textContent = deplie ? "Lire moins" : "Lire plus"
    this.boutonTarget.classList.toggle("fr-icon-arrow-down-s-line", !deplie)
    this.boutonTarget.classList.toggle("fr-icon-arrow-up-s-line", deplie)
  }
}
