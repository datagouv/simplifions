import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tag"]

  connect() {
    this.deplierOngletAffiche = this.deplierOngletAffiche.bind(this)
    this.element.addEventListener("dsfr.disclose", this.deplierOngletAffiche)
  }

  disconnect() {
    this.element.removeEventListener("dsfr.disclose", this.deplierOngletAffiche)
  }

  afficher() {
    this.deplier(this.element)
  }

  deplierOngletAffiche({ target }) {
    if (target.classList.contains("fr-tabs__panel")) requestAnimationFrame(() => this.deplier(target))
  }

  deplier(zone) {
    const choisis = this.choisis()
    zone.querySelectorAll("[data-filtre] > .fr-collapse").forEach((volet) => {
      window.dsfr(volet).collapse[choisis.includes(volet.parentElement.dataset.filtre) ? "disclose" : "conceal"]()
    })
    zone.querySelectorAll("[data-filtre][data-controller~=section-depliable]").forEach((section) => {
      this.dispatch("deplier", { target: section, detail: { deplie: !choisis.length || choisis.includes(section.dataset.filtre) } })
    })
  }

  choisis() {
    return this.tagTargets.filter((tag) => tag.getAttribute("aria-pressed") === "true").map((tag) => tag.dataset.filtre)
  }
}
