import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["texte", "bouton", "libelle"]

  connect() {
    this.afficher(false)
    this.mesure = new ResizeObserver(() => this.montrerLeBoutonSiLeTexteDepasse())
    this.mesure.observe(this.texteTarget)
  }

  disconnect() {
    this.mesure.disconnect()
  }

  montrerLeBoutonSiLeTexteDepasse() {
    if (!this.texteTarget.classList.contains("lire-plus--replie")) return
    const depasse = this.texteTarget.scrollHeight > this.texteTarget.clientHeight
    this.boutonTarget.classList.toggle("fr-hidden", !depasse)
  }

  basculer() {
    this.afficher(this.texteTarget.classList.contains("lire-plus--replie"))
  }

  deplier() {
    this.afficher(true)
  }

  afficher(deplie) {
    this.texteTarget.classList.toggle("lire-plus--replie", !deplie)
    this.boutonTarget.setAttribute("aria-expanded", deplie)
    this.libelleTarget.textContent = deplie ? "Lire moins" : "Lire plus"
  }
}
