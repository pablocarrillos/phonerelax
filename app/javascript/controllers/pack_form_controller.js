import { Controller } from "@hotwired/stimulus"

// Formulario de producto: al marcar «Es un pack», el precio pasa a calcularse
// automáticamente a partir de los componentes (campo bloqueado con nota) y el
// escalado propio deja de aplicar (sección oculta). El cálculo real lo hace el
// servidor (Product#sync_pack_price); esto solo refleja el estado en el form.
export default class extends Controller {
  static targets = ["pack", "price", "priceNote", "tiers"]

  connect() { this.refresh() }

  refresh() {
    const on = this.packTarget.checked
    if (this.hasPriceTarget) this.priceTarget.disabled = on
    if (this.hasPriceNoteTarget) this.priceNoteTarget.hidden = !on
    if (this.hasTiersTarget) this.tiersTarget.hidden = on
  }
}
