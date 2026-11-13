import { Controller } from "@hotwired/stimulus"

const ESPACE_AU_DESSUS_DU_TITRE = 16

let filtreEnvoye = false

export default class extends Controller {
  static targets = ["compteur", "tri", "boutonTri"]

  connect() {
    if (filtreEnvoye) addEventListener("turbo:load", () => this.remonterAuTitre(), { once: true })
    filtreEnvoye = false
    this.comparerTri()
  }

  remonterAuTitre() {
    const titre = document.querySelector("h1")
    if (titre) window.scrollTo(0, window.scrollY + titre.getBoundingClientRect().top - ESPACE_AU_DESSUS_DU_TITRE)
    if (this.hasCompteurTarget) this.compteurTarget.focus({ preventScroll: true })
  }

  comparerTri() {
    if (!this.hasTriTarget || !this.hasBoutonTriTarget) return
    const options = [...this.triTarget.options]
    const origine = options.find((option) => option.defaultSelected) || options[0]
    this.boutonTriTarget.classList.toggle("fr-hidden", this.triTarget.value === origine.value)
  }

  retenir() {
    filtreEnvoye = true
  }

  nettoyer(event) {
    const parametres = event.formData || event.detail.url.searchParams
    const dernieres = new Map()
    for (const [nom, valeur] of parametres) dernieres.set(nom, valeur)
    for (const nom of dernieres.keys()) parametres.delete(nom)
    for (const [nom, valeur] of dernieres) if (valeur !== "") parametres.append(nom, valeur)
  }
}
