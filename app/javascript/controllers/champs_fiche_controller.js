import { Controller } from "@hotwired/stimulus"

const rempli = (saisie) => saisie.type !== "checkbox" && (saisie.value || saisie.defaultValue)

export default class extends Controller {
  static values = { horsFiches: Array }

  basculer() {
    const horsFiche = this.horsFichesValue.includes(this.element.value)
    this.element.form.querySelectorAll("[data-champ-fiche]").forEach((champ) => {
      const saisies = [...champ.querySelectorAll("input, textarea")]
      const masque = horsFiche && !("rempliEnBase" in champ.dataset) && !champ.querySelector("img") && !saisies.some(rempli)
      champ.classList.toggle("fr-hidden", masque)
      saisies.forEach((saisie) => { saisie.disabled = masque })
    })
  }
}
