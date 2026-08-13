import { Controller } from "@hotwired/stimulus"

// Démonstrateur : interroge l'API Recherche d'entreprises avec un SIRET saisi.
export default class extends Controller {
  static targets = ["input", "button", "error", "loading", "result",
    "name", "siret", "adresse", "adresseWrapper", "naf", "nafWrapper",
    "forme", "formeWrapper", "etat"]

  reset() {
    this.errorTarget.textContent = ""
    this.errorTarget.hidden = true
    this.inputTarget.closest(".fr-input-group").classList.remove("fr-input-group--error")
    this.resultTarget.hidden = true
  }

  async search(event) {
    event.preventDefault()
    const siret = this.inputTarget.value.trim()
    if (!/^\d{14}$/.test(siret)) {
      this.fail("Le numéro SIRET doit contenir exactement 14 chiffres.")
      return
    }

    this.reset()
    this.loadingTarget.hidden = false
    this.buttonTarget.disabled = true

    try {
      const siren = siret.slice(0, 9)
      const response = await fetch(`https://recherche-entreprises.api.gouv.fr/search?q=${siren}&page=1&per_page=1`)
      if (!response.ok) throw new Error()
      const data = await response.json()
      if (!data.results?.length) {
        this.fail("Aucune entreprise trouvée pour ce numéro SIRET.")
        return
      }
      this.display(data.results[0], siret)
    } catch {
      this.fail("Une erreur est survenue lors de la requête. Vérifiez le numéro et réessayez.")
    } finally {
      this.loadingTarget.hidden = true
      this.buttonTarget.disabled = false
    }
  }

  fail(message) {
    this.loadingTarget.hidden = true
    this.buttonTarget.disabled = false
    this.resultTarget.hidden = true
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
    this.inputTarget.closest(".fr-input-group").classList.add("fr-input-group--error")
  }

  display(entreprise, siret) {
    this.nameTarget.textContent = entreprise.nom_complet || entreprise.nom_raison_sociale || "—"
    this.siretTarget.textContent = `SIRET : ${this.formatSiret(entreprise.siege?.siret || siret)}`

    this.fill(this.adresseWrapperTarget, this.adresseTarget, entreprise.siege?.adresse)
    this.fill(this.nafWrapperTarget, this.nafTarget, entreprise.siege?.activite_principale)
    this.fill(this.formeWrapperTarget, this.formeTarget,
      entreprise.siege?.libelle_nature_juridique || entreprise.nature_juridique)

    const actif = entreprise.etat_administratif === "A"
    this.etatTarget.textContent = actif ? "Actif" : "Fermé"
    this.etatTarget.classList.toggle("fr-badge--success", actif)
    this.etatTarget.classList.toggle("fr-badge--error", !actif)

    this.resultTarget.hidden = false
  }

  fill(wrapper, target, value) {
    wrapper.hidden = !value
    target.textContent = value || ""
  }

  formatSiret(siret) {
    return siret.replace(/(\d{3})(\d{3})(\d{3})(\d{5})/, "$1 $2 $3 $4")
  }
}
