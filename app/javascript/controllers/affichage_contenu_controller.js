import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tag", "donnee", "solution", "bandeau", "filtres", "menu", "compteur"]

  connect() {
    this.observateur = new MutationObserver((changements) => {
      changements.forEach(({ target }) => this.synchroniser(target))
      this.afficher()
    })
    this.tagTargets.forEach((tag) => this.observateur.observe(tag, { attributeFilter: ["aria-pressed"] }))
    this.voletsOuverts = new WeakMap()
    this.memoriser = this.memoriser.bind(this)
    this.restaurer = this.restaurer.bind(this)
    this.element.addEventListener("dsfr.conceal", this.memoriser)
    this.element.addEventListener("dsfr.disclose", this.restaurer)
    this.visibilite = new IntersectionObserver(([bandeau]) => this.montrerFiltres(!bandeau.isIntersecting))
    this.visibilite.observe(this.bandeauTarget)
    this.fermerMenu = this.fermerMenu.bind(this)
    document.addEventListener("click", this.fermerMenu)
    document.addEventListener("keydown", this.fermerMenu)
  }

  disconnect() {
    this.observateur.disconnect()
    this.element.removeEventListener("dsfr.conceal", this.memoriser)
    this.element.removeEventListener("dsfr.disclose", this.restaurer)
    this.visibilite.disconnect()
    document.removeEventListener("click", this.fermerMenu)
    document.removeEventListener("keydown", this.fermerMenu)
  }

  montrerFiltres(visibles) {
    this.filtresTarget.classList.toggle("fr-hidden", !visibles)
    if (!visibles) this.replierMenu()
  }

  fermerMenu(event) {
    const dehors = event.type === "click" && ![this.filtresTarget, this.menuTarget].some((zone) => zone.contains(event.target))
    if (dehors || event.key === "Escape") this.replierMenu()
  }

  replierMenu() {
    if (this.menuTarget.classList.contains("fr-collapse--expanded")) window.dsfr(this.menuTarget).collapse.conceal()
  }

  synchroniser(modele) {
    const etat = modele.getAttribute("aria-pressed")
    this.tagTargets
      .filter((tag) => tag.dataset.filtre === modele.dataset.filtre && tag.getAttribute("aria-pressed") !== etat)
      .forEach((tag) => tag.setAttribute("aria-pressed", etat))
  }

  afficher() {
    const choisis = [...new Set(this.tagTargets.filter((tag) => tag.getAttribute("aria-pressed") === "true").map((tag) => tag.dataset.filtre))]
    const ouvert = (volet, sansChoix) => (choisis.length ? choisis.includes(volet.dataset.filtre) : sansChoix)
    this.compteurTarget.textContent = choisis.length ? `(${choisis.length})` : ""
    this.voletsOuverts = new WeakMap()
    this.donneeTargets.forEach((volet) => window.dsfr(volet).collapse[ouvert(volet, false) ? "disclose" : "conceal"]())
    this.solutionTargets.forEach((volet) => { volet.open = ouvert(volet, true) })
  }

  memoriser(event) {
    if (!event.target.classList.contains("fr-tabs__panel")) return
    this.voletsOuverts.set(event.target, [...event.target.querySelectorAll(".fr-collapse--expanded")])
  }

  restaurer(event) {
    const volets = this.voletsOuverts.get(event.target)
    if (!volets) return
    requestAnimationFrame(() => volets.forEach((volet) => window.dsfr(volet).collapse.disclose()))
  }
}
