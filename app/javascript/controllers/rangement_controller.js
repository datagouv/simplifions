import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: "[data-poignee]",
      draggable: "[data-deplacement]",
      animation: 150,
      onEnd: this.ranger
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  ranger = ({ item, oldDraggableIndex, newDraggableIndex }) => {
    if (oldDraggableIndex === newDraggableIndex) return

    const bouton = document.getElementById(item.dataset.deplacement).querySelector("[name=position]")
    bouton.value = newDraggableIndex + 1
    bouton.form.requestSubmit(bouton)
  }
}
