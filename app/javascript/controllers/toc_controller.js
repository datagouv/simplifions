import { Controller } from "@hotwired/stimulus"

// Scroll-spy du sommaire d'article : surligne l'entrée dont la section est en cours de lecture.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sections = this.linkTargets
      .map((link) => document.getElementById(link.getAttribute("href").slice(1)))
      .filter(Boolean)
    if (!this.sections.length) return

    this.onScroll = () => {
      if (this.frame) return
      this.frame = requestAnimationFrame(() => {
        this.frame = null
        this.update()
      })
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })

    const initial = window.location.hash.slice(1)
    if (this.sections.some((section) => section.id === initial)) this.activate(initial)
    else this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  select(event) {
    this.activate(event.currentTarget.getAttribute("href").slice(1))
  }

  update() {
    const threshold = window.innerHeight * 0.2
    let current = this.sections[0]
    for (const section of this.sections) {
      if (section.getBoundingClientRect().top <= threshold) current = section
    }
    this.activate(current.id)
  }

  activate(id) {
    this.linkTargets.forEach((link) => {
      if (link.getAttribute("href") === `#${id}`) link.setAttribute("aria-current", "page")
      else link.removeAttribute("aria-current")
    })
  }
}
