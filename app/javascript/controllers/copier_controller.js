import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bouton", "statut"]

  connect() {
    if (navigator.clipboard) this.boutonTargets.forEach((bouton) => bouton.classList.remove("fr-hidden"))
  }

  async copier({ params: { texte, confirmation } }) {
    this.statutTarget.textContent = ""
    try {
      await navigator.clipboard.writeText(texte)
      this.statutTarget.textContent = confirmation
    } catch {
      this.statutTarget.textContent = "Copie impossible : sélectionnez le texte et copiez-le avec Ctrl+C."
    }
  }
}
