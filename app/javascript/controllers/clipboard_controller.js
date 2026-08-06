import { Controller } from "@hotwired/stimulus"

// Copia al portapapeles el texto del atributo data-clipboard-text-value y da
// una confirmación breve en el propio botón.
export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = this.element.textContent
      this.element.textContent = "¡Copiada!"
      setTimeout(() => { this.element.textContent = original }, 1500)
    })
  }
}
