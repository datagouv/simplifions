import { Controller } from "@hotwired/stimulus"

// Bloc « Sont mentionnés dans cet article » : boutons Précédent / Suivant à la place de la barre de défilement.
export default class extends Controller {
  static targets = ["track", "nav"]

  connect() {
    this.trackTarget.classList.add("carousel-track--boutons")
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
    this.scroll(-this.trackTarget.clientWidth)
  }

  next() {
    this.scroll(this.trackTarget.clientWidth)
  }

  scroll(left) {
    const behavior = matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
    this.trackTarget.scrollBy({ left, behavior })
  }
}
