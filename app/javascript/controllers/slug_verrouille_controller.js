import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["saisie", "bouton"]

  deverrouiller() {
    delete this.saisieTarget.dataset.verrouille
    this.saisieTarget.disabled = false
    this.boutonTarget.remove()
    this.saisieTarget.focus()
  }
}
