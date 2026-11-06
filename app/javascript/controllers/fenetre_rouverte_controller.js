import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    requestAnimationFrame(() => window.dsfr(this.element).modal.disclose())
  }
}
