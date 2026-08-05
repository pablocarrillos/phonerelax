import { Controller } from "@hotwired/stimulus"

// Despliega/colapsa un <details> al entrar/salir el puntero. El clic del
// summary sigue funcionando, así que en pantallas táctiles no se pierde nada.
export default class extends Controller {
  open() { this.element.open = true }
  close() { this.element.open = false }
}
