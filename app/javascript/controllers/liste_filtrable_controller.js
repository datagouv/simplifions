import { Controller } from "@hotwired/stimulus"

const sansAccent = (texte) => texte.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase()
const pluriel = (nombre, mot) => `${nombre} ${mot}${nombre > 1 ? "s" : ""}`

export default class extends Controller {
  static targets = ["filtre", "element", "compte"]

  connect() {
    this.filtrer()
  }

  filtrer() {
    const mots = sansAccent(this.filtreTarget.value).split(/\s+/).filter(Boolean)
    this.elementTargets.forEach((element) => {
      const texte = sansAccent(element.querySelector("label").textContent)
      const visible = mots.length ? mots.every((mot) => texte.includes(mot)) : element.querySelector("input").checked
      element.classList.toggle("fr-hidden", !visible)
    })
    this.compter()
  }

  compter() {
    const coches = this.elementTargets.filter((element) => element.querySelector("input").checked).length
    const affiches = this.elementTargets.filter((element) => !element.classList.contains("fr-hidden")).length
    const total = this.elementTargets.length
    this.compteTarget.textContent = this.filtreTarget.value.trim()
      ? `${pluriel(affiches, "résultat")} sur ${total}, ${pluriel(coches, "coché")}`
      : `${pluriel(coches, "coché")} sur ${total}`
  }
}
