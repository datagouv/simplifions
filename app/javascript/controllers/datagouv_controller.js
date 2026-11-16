import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, categories: Array }

  connect() {
    this.formulaire = this.element.closest("form")
    this.formulaire.addEventListener("change", this.relancer)
  }

  disconnect() {
    this.formulaire.removeEventListener("change", this.relancer)
  }

  relancer = ({ target }) => {
    const uid = this.champ("uid_datagouv")
    const categorie = this.champ("categorie")
    if (target !== uid && target !== categorie) return
    if (!uid.value.trim() || !this.categoriesValue.includes(categorie.value)) {
      this.element.removeAttribute("src")
      this.element.replaceChildren()
      return
    }
    this.element.src = `${this.urlValue}?${new URLSearchParams({ uid: uid.value, categorie: categorie.value })}`
  }

  remplirLeNom() {
    const titre = this.element.querySelector("[data-titre-datagouv]")?.dataset.titreDatagouv
    const nom = this.champ("nom")
    if (!titre || (nom.value.trim() && nom.value !== nom.dataset.titreRepris)) return
    nom.value = titre
    nom.dataset.titreRepris = titre
    nom.dispatchEvent(new Event("input", { bubbles: true }))
  }

  champ(nom) {
    return this.formulaire.elements[`solution[${nom}]`]
  }
}
