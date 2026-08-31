import { Controller } from "@hotwired/stimulus"

// Filtre par mots-clés et pagination du tableau des endpoints utiles d'une recommandation.
export default class extends Controller {
  static targets = ["input", "row", "empty", "footer", "count", "pagination"]
  static values = { perPage: { type: Number, default: 4 } }

  connect() {
    this.page = 0
    this.render()
  }

  filter() {
    this.page = 0
    this.render()
  }

  goTo(event) {
    event.preventDefault()
    const link = event.currentTarget
    if (link.getAttribute("aria-disabled") === "true") return
    this.page = Number(link.dataset.page)
    this.render()
  }

  render() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const matching = this.rowTargets.filter((row) => !query || row.textContent.toLowerCase().includes(query))
    const pageCount = Math.ceil(matching.length / this.perPageValue)
    const start = this.page * this.perPageValue
    const shown = new Set(matching.slice(start, start + this.perPageValue))

    this.rowTargets.forEach((row) => { row.hidden = !shown.has(row) })
    this.emptyTarget.hidden = matching.length > 0
    this.footerTarget.hidden = pageCount <= 1
    this.countTarget.textContent = `${matching.length} endpoint${matching.length > 1 ? "s" : ""}`
    this.paginationTarget.innerHTML = pageCount > 1 ? this.paginationHtml(pageCount) : ""
  }

  paginationHtml(pageCount) {
    const link = (page, classes, label, title) => {
      const disabled = page < 0 || page >= pageCount
      const current = page === this.page && !title
      return `<li><a href="#" class="fr-pagination__link ${classes}${disabled ? " fr-pagination__link--disabled" : ""}"
        data-page="${page}" data-action="endpoints#goTo"${disabled ? ' aria-disabled="true"' : ""}${current ? ' aria-current="page"' : ""}${title ? ` title="${title}"` : ""}>${label}</a></li>`
    }
    const pages = Array.from({ length: pageCount }, (_, i) =>
      link(i, "fr-unhidden-lg", String(i + 1), i === this.page ? "" : `Page ${i + 1}`)).join("")
    return `<ul class="fr-pagination__list">
      ${link(0, "fr-pagination__link--first", '<span class="fr-sr-only">Première page</span>', "Première page")}
      ${link(this.page - 1, "fr-pagination__link--prev fr-pagination__link--lg-label", "Page précédente", "Page précédente")}
      ${pages}
      ${link(this.page + 1, "fr-pagination__link--next fr-pagination__link--lg-label", "Page suivante", "Page suivante")}
      ${link(pageCount - 1, "fr-pagination__link--last", '<span class="fr-sr-only">Dernière page</span>', "Dernière page")}
    </ul>`
  }
}
