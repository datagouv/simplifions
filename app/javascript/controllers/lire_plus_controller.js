import { Controller } from "@hotwired/stimulus"

const ARRONDI_DU_NAVIGATEUR = 1

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
    const depasse = this.texteTarget.scrollHeight - this.texteTarget.clientHeight > ARRONDI_DU_NAVIGATEUR
    this.boutonTarget.classList.toggle("fr-hidden", !depasse)
    this.texteTarget.classList.toggle("lire-plus--coupe", depasse)
  }

  basculer() {
    const deplie = this.texteTarget.classList.contains("lire-plus--replie")
    this.afficher(deplie)
    if (!deplie) this.element.scrollIntoView({ block: "nearest" })
  }

  deplier() {
    if (!this.boutonTarget.classList.contains("fr-hidden")) this.afficher(true)
  }

  afficher(deplie) {
    this.texteTarget.classList.toggle("lire-plus--replie", !deplie)
    this.boutonTarget.setAttribute("aria-expanded", deplie)
    this.boutonTarget.classList.toggle("fr-icon-arrow-down-s-line", !deplie)
    this.boutonTarget.classList.toggle("fr-icon-arrow-up-s-line", deplie)
    this.libelleTarget.textContent = deplie ? "Lire moins" : "Lire plus"
  }
}
