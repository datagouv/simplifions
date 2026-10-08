import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["champ"]

  choisir({ target }) {
    if (target.dataset.onglet) this.champTarget.value = target.dataset.onglet
  }
}
