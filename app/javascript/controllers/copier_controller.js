import { Controller } from "@hotwired/stimulus"

// Copie l'objet ou le modèle de message de la page « Nous contacter ».
// Sans JS, les boutons restent cachés : l'objet et le modèle sont lisibles et sélectionnables.
export default class extends Controller {
  static targets = ["source", "bouton", "statut"]

  connect() {
    if (navigator.clipboard) this.boutonTargets.forEach((bouton) => { bouton.hidden = false })
  }

  // Sans paramètre « texte », le bouton copie le modèle de message.
  async copier({ params: { texte, confirmation } }) {
    try {
      await navigator.clipboard.writeText(texte || this.sourceTarget.value)
      this.statutTarget.textContent = confirmation
    } catch {
      if (!texte) this.sourceTarget.select()
      this.statutTarget.textContent = "Copie impossible : sélectionnez le texte et copiez-le avec Ctrl+C."
    }
  }
}
