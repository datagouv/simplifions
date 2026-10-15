import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  trier({ currentTarget, params: { cle, ordre: ordreParDefaut } }) {
    const enTete = currentTarget.closest("th")
    const actuel = enTete.getAttribute("aria-sort")
    const ordre = actuel ? (actuel === "ascending" ? "descending" : "ascending") : ordreParDefaut
    const sens = ordre === "ascending" ? 1 : -1
    const corps = this.element.tBodies[0]
    const lignes = [...corps.rows]

    lignes.sort((a, b) => {
      const parNom = a.dataset.nom.localeCompare(b.dataset.nom, "fr", { sensitivity: "base" })
      if (cle === "nom") return sens * parNom
      return sens * (Number(a.dataset.integrees) - Number(b.dataset.integrees)) || parNom
    })
    corps.append(...lignes)

    this.element.querySelectorAll("th[aria-sort]").forEach((th) => {
      th.removeAttribute("aria-sort")
      th.querySelector(".fr-btn--sort").classList.remove("fr-btn--sort-asc", "fr-btn--sort-desc")
    })
    enTete.setAttribute("aria-sort", ordre)
    currentTarget.classList.add(ordre === "ascending" ? "fr-btn--sort-asc" : "fr-btn--sort-desc")
  }
}
