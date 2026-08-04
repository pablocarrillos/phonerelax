import { Controller } from "@hotwired/stimulus"

// Menú de navegación en móvil: el botón hamburguesa abre y cierra el panel
// desplegable. Al pulsar cualquier enlace del menú se cierra solo.
export default class extends Controller {
  static targets = ["toggle"]

  toggle() {
    const open = this.element.classList.toggle("nav-open")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", open ? "true" : "false")
  }

  close() {
    if (!this.element.classList.contains("nav-open")) return
    this.element.classList.remove("nav-open")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  // Cierra el menú al pulsar un enlace (útil en anclas de la misma página, que
  // no recargan). El selector de idioma también son enlaces y cierra igual.
  closeOnLink(event) {
    if (event.target.closest("a")) this.close()
  }
}
