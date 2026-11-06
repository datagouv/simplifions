import { Controller } from "@hotwired/stimulus"

const QUESTION = "Quitter sans enregistrer les modifications ?"
const enregistreSurPlace = (formulaire) => "enregistreSurPlace" in formulaire.dataset
const coche = (champ) => champ.type === "checkbox" || champ.type === "radio"
const options = (champ) => (champ.tagName === "SELECT" ? [...champ.options] : [])
const differe = (champ) =>
  coche(champ) ? champ.checked !== champ.defaultChecked
    : options(champ).some((option) => option.selected !== option.defaultSelected) || ("defaultValue" in champ && champ.value !== champ.defaultValue)
const remettre = (champ) => {
  if (coche(champ)) champ.checked = champ.defaultChecked
  else if (champ.tagName === "SELECT") options(champ).forEach((option) => (option.selected = option.defaultSelected))
  else champ.value = champ.defaultValue
}

export default class extends Controller {
  static values = { modifie: Boolean, fiche: String }

  connect() {
    document.addEventListener("submit", this.soumettre, true)
    document.addEventListener("turbo:submit-start", this.partir)
    document.addEventListener("turbo:submit-end", this.terminer)
    document.addEventListener("turbo:before-visit", this.visiter)
    window.navigation?.addEventListener("navigate", this.revenir)
    window.addEventListener("beforeunload", this.decharger)
  }

  disconnect() {
    document.removeEventListener("submit", this.soumettre, true)
    document.removeEventListener("turbo:submit-start", this.partir)
    document.removeEventListener("turbo:submit-end", this.terminer)
    document.removeEventListener("turbo:before-visit", this.visiter)
    window.navigation?.removeEventListener("navigate", this.revenir)
    window.removeEventListener("beforeunload", this.decharger)
  }

  modifieValueChanged() {
    const enregistrer = [...this.element.elements].find((champ) => champ.hasAttribute("data-enregistrer"))
    if (enregistrer) enregistrer.disabled = !this.modifieValue
  }

  marquer(event) {
    if (event.target.name && event.target.form === this.element) this.modifieValue = true
  }

  quitter() {
    if (!this.modifieValue) return true
    if (!confirm(QUESTION)) return false
    this.element.reset()
    this.modifieValue = false
    return true
  }

  annuler({ currentTarget }) {
    if (this.ficheValue) {
      this.modifieValue = false
      return window.Turbo.visit(this.ficheValue, { action: "replace" })
    }
    currentTarget.querySelectorAll("input, textarea, select").forEach(remettre)
    this.modifieValue = [...this.element.elements].some((champ) => champ.name && differe(champ))
  }

  soumettre = (event) => {
    if (event.target === this.element || enregistreSurPlace(event.target)) return
    if (this.modifieValue && !confirm(QUESTION)) event.preventDefault()
  }

  partir = (event) => {
    if (enregistreSurPlace(event.target)) return
    this.modifieAvantEnvoi = this.modifieValue
    this.modifieValue = false
  }

  terminer = (event) => {
    if (enregistreSurPlace(event.target)) return
    if (!event.detail.success) this.modifieValue = this.modifieAvantEnvoi
  }

  visiter = (event) => {
    if (!this.quitter()) event.preventDefault()
  }

  revenir = (event) => {
    if (event.navigationType === "traverse" && event.cancelable && !this.quitter()) event.preventDefault()
  }

  decharger = (event) => {
    if (this.modifieValue) event.preventDefault()
  }
}
