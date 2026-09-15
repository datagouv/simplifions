import { Controller } from "@hotwired/stimulus"

// Bloc « Sont mentionnés dans cet article » : boutons Précédent / Suivant, sans barre de défilement.
export default class extends Controller {
  static targets = ["track", "nav"]

  connect() {
    this.navTarget.classList.toggle("fr-hidden", this.trackTarget.scrollWidth <= this.trackTarget.clientWidth)
  }

  prev() {
    this.trackTarget.scrollBy({ left: -this.trackTarget.clientWidth, behavior: "smooth" })
  }

  next() {
    this.trackTarget.scrollBy({ left: this.trackTarget.clientWidth, behavior: "smooth" })
  }
}
