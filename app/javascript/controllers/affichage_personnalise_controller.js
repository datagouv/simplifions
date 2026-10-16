import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["haut", "bouton", "bandeau"]

  connect() {
    this.defilement = new IntersectionObserver(([haut]) => this.replierApresDefilement(!haut.isIntersecting))
    this.defilement.observe(this.hautTarget)
  }

  disconnect() {
    this.defilement.disconnect()
  }

  replierApresDefilement(defile) {
    this.boutonTarget.classList.toggle("fr-hidden", !defile)
    window.dsfr(this.bandeauTarget).collapse[defile ? "conceal" : "disclose"]()
  }

  ouvrirLesAccordeonsApi({ target }) {
    if (target.dataset.filtreTag !== "api" || target.getAttribute("aria-pressed") !== "true") return
    this.element.querySelectorAll("[data-filtre=api] > .fr-collapse").forEach((volet) => window.dsfr(volet).collapse.disclose())
  }
}
