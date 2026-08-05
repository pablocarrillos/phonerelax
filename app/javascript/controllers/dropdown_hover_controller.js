import { Controller } from "@hotwired/stimulus"

// Despliega/colapsa un <details> al entrar/salir el puntero. El cierre lleva
// un pequeño retardo y se cancela si el puntero vuelve a entrar: así se puede
// bajar en diagonal hasta las opciones sin que el menú se repliegue por el
// camino. El clic del summary sigue funcionando en pantallas táctiles.
export default class extends Controller {
  open() {
    clearTimeout(this.closeTimer)
    this.element.open = true
  }

  close() {
    clearTimeout(this.closeTimer)
    this.closeTimer = setTimeout(() => { this.element.open = false }, 350)
  }

  disconnect() { clearTimeout(this.closeTimer) }
}
