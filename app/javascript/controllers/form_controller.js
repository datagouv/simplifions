import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    for (const field of this.element.elements) field.disabled = field.name && !field.value
    this.element.requestSubmit()
  }
}
