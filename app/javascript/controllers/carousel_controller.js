import { Controller } from "@hotwired/stimulus"

// Bloc « Sont mentionnés dans cet article » : boutons Précédent / Suivant, sans barre de défilement.
export default class extends Controller {
  static targets = ["track", "nav"]

  connect() {
    this.update = () => {
      this.navTarget.classList.toggle("fr-hidden", this.trackTarget.scrollWidth <= this.trackTarget.clientWidth)
    }
    this.update()
    window.addEventListener("resize", this.update, { passive: true })
  }

  disconnect() {
    window.removeEventListener("resize", this.update)
  }

  prev() {
    this.trackTarget.scrollBy({ left: -this.trackTarget.clientWidth, behavior: "smooth" })
  }

  next() {
    this.trackTarget.scrollBy({ left: this.trackTarget.clientWidth, behavior: "smooth" })
  }
}
