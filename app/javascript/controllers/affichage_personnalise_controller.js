import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["haut", "bouton", "bandeau"]

  connect() {
    this.defilement = new IntersectionObserver(([haut]) => { if (!haut.isIntersecting) this.replierApresDefilement() })
    this.defilement.observe(this.hautTarget)
  }

  disconnect() {
    this.defilement.disconnect()
  }

  replierApresDefilement() {
    this.boutonTarget.classList.remove("fr-hidden")
    window.dsfr(this.bandeauTarget).collapse.conceal()
  }

  ouvrirLesAccordeonsApi({ target }) {
    if (target.dataset.filtreTag !== "api" || target.getAttribute("aria-pressed") !== "true") return
    this.element.querySelectorAll("[data-filtre=api] > .fr-collapse").forEach((volet) => window.dsfr(volet).collapse.disclose())
  }
}
