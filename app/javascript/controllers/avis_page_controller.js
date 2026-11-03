import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choix", "envoi", "merci", "manque", "remarque"]
  static values = { lu: Boolean }

  get moment() {
    return this.luValue ? "après lecture" : "avant lecture"
  }

  activer() {
    this.envoiTarget.disabled = false
  }

  envoyer() {
    const choisi = this.choixTarget.querySelector("input:checked")
    if (!choisi) return

    this.choixTarget.dispatchEvent(new CustomEvent("matomo:evenement", {
      bubbles: true, detail: { action: "Trouver la page utile", choix: `${choisi.value} (${this.moment})` }
    }))
    this.choixTarget.disabled = true
    this.envoiTarget.classList.add("fr-hidden")
    const utile = choisi.value === "Oui"
    this.manqueTarget.classList.toggle("fr-hidden", utile)
    this.remarqueTarget.classList.toggle("fr-hidden", !utile)
    this.merciTarget.classList.remove("fr-hidden")
    this.merciTarget.focus()
  }
}
