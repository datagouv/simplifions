import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.ouvrir(window.location.hash)) this.element.scrollIntoView()
  }

  suivre(event) {
    const lien = event.target.closest('a[href^="#"]')
    if (lien) this.ouvrir(lien.getAttribute("href"))
  }

  ouvrir(ancre) {
    const id = decodeURIComponent(ancre.slice(1))
    const onglet = id && this.element.querySelector(`[role="tab"][aria-controls="${CSS.escape(id)}"]`)
    onglet?.click()
    return Boolean(onglet)
  }
}
