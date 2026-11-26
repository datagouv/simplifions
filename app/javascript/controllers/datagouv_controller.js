import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cadre", "attente", "organisationAbsente"]
  static values = { url: String, attente: String, sansIdentifiant: String, repris: String, organisationAbsente: String, champOrganisation: String }

  connect() {
    this.formulaire = this.element.closest("form")
  }

  recuperer() {
    const uid = this.champ("uid_datagouv").value.trim()
    if (!uid) {
      this.cadreTarget.removeAttribute("src")
      this.cadreTarget.replaceChildren()
      this.signalerLOrganisationAbsente()
      this.attenteTarget.textContent = this.sansIdentifiantValue
      return
    }
    const adresse = `${this.urlValue}?${new URLSearchParams({ uid, categorie: this.champ("categorie").value })}`
    this.cadreTarget.src === adresse ? this.cadreTarget.reload() : (this.cadreTarget.src = adresse)
  }

  attendre() {
    this.cadreTarget.replaceChildren()
    this.signalerLOrganisationAbsente()
    this.attenteTarget.textContent = this.attenteValue
  }

  finirLAttente() {
    this.attenteTarget.textContent = ""
  }

  reprendre() {
    const bloc = this.cadreTarget.querySelector("[data-titre-datagouv]")
    this.signalerLOrganisationAbsente(bloc?.dataset.organisationAbsente)
    if (!bloc) return
    const repris = [this.remplirLeNom(bloc.dataset.titreDatagouv), this.cocherLOrganisation(bloc.dataset.organisationDatagouv)].filter(Boolean)
    if (repris.length) this.attenteTarget.textContent = `${repris.join(" et ")} ${this.reprisValue}`
  }

  remplirLeNom(titre) {
    const nom = this.champ("nom")
    if (!titre || (nom.value.trim() && nom.value !== nom.dataset.titreRepris)) return
    nom.value = titre
    nom.dataset.titreRepris = titre
    nom.dispatchEvent(new Event("input", { bubbles: true }))
    return "Nom"
  }

  cocherLOrganisation(id) {
    const caseACocher = id && this.formulaire.querySelector(`input[name="solution[organisation_ids][]"][value="${CSS.escape(id)}"]`)
    if (!caseACocher || caseACocher.checked) return
    caseACocher.checked = true
    caseACocher.closest(".fr-fieldset__element")?.classList.remove("fr-hidden")
    caseACocher.dispatchEvent(new Event("change", { bubbles: true }))
    return "organisation"
  }

  signalerLOrganisationAbsente(nom) {
    const message = nom && Object.assign(document.createElement("p"), {
      className: "fr-message fr-message--warning fr-mb-1w", textContent: this.organisationAbsenteValue.replace("%{nom}", nom)
    })
    this.organisationAbsenteTarget.replaceChildren(...[message].filter(Boolean))
    const champ = document.getElementById(this.champOrganisationValue)
    if (!nom || !champ || (champ.value.trim() && champ.value !== champ.dataset.nomRepris)) return
    champ.value = nom
    champ.dataset.nomRepris = nom
  }

  champ(nom) {
    return this.formulaire.elements[`solution[${nom}]`]
  }
}
