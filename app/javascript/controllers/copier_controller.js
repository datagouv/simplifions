import { Controller } from "@hotwired/stimulus"

const ICONES = ["fr-icon-clipboard-line", "fr-icon-check-line", "fr-icon-error-line"]
const DUREE_DU_SIGNAL = 3000

export default class extends Controller {
  static targets = ["bouton", "statut"]

  connect() {
    if (navigator.clipboard) this.boutonTargets.forEach((bouton) => bouton.classList.remove("fr-hidden"))
  }

  async copier({ currentTarget: bouton, params: { texte, confirmation } }) {
    this.statutTarget.textContent = ""
    try {
      await navigator.clipboard.writeText(texte)
      this.statutTarget.textContent = confirmation
      this.signaler(bouton, confirmation, "fr-icon-check-line")
    } catch {
      this.statutTarget.textContent = "Copie impossible : sélectionnez le texte et copiez-le avec Ctrl+C."
      this.signaler(bouton, "Copie impossible", "fr-icon-error-line")
    }
  }

  signaler(bouton, libelle, icone) {
    bouton.dataset.libelle ??= bouton.textContent
    clearTimeout(Number(bouton.dataset.retour))
    this.afficher(bouton, libelle, icone)
    bouton.dataset.retour = setTimeout(() => this.afficher(bouton, bouton.dataset.libelle, "fr-icon-clipboard-line"), DUREE_DU_SIGNAL)
  }

  afficher(bouton, libelle, icone) {
    bouton.textContent = libelle
    bouton.classList.remove(...ICONES)
    bouton.classList.add(icone)
  }
}
