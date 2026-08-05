import { Controller } from "@hotwired/stimulus"

// Formulario de producto: al marcar «Es un pack», el precio y el stock pasan a
// calcularse automáticamente a partir de los componentes (campos bloqueados
// con nota) y el escalado propio deja de aplicar (sección oculta). El cálculo
// real lo hace el servidor (Product#sync_pack_price y #available_stock); esto
// solo refleja el estado en el formulario.
export default class extends Controller {
  static targets = ["pack", "price", "priceNote", "stock", "stockNote", "tiers"]

  connect() { this.refresh() }

  refresh() {
    const on = this.packTarget.checked
    if (this.hasPriceTarget) this.priceTarget.disabled = on
    if (this.hasPriceNoteTarget) this.priceNoteTarget.hidden = !on
    if (this.hasStockTarget) this.stockTarget.disabled = on
    if (this.hasStockNoteTarget) this.stockNoteTarget.hidden = !on
    if (this.hasTiersTarget) this.tiersTarget.hidden = on
  }
}
