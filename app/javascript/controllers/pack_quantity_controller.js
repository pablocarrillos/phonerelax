import { Controller } from "@hotwired/stimulus"

// Ficha de un pack: al cambiar la cantidad de packs recalcula en vivo las
// cantidades, precios, ahorros y el total pidiendo el desglose al servidor (que
// aplica el escalado al total de unidades). Limita la cantidad al stock del pack.
export default class extends Controller {
  static targets = ["quantity", "price", "row", "totalBase", "totalPack", "totalSaving", "note"]
  static values = { url: String, available: Number }

  connect() {
    if (this.hasQuantityTarget && this.availableValue > 0) this.quantityTarget.max = this.availableValue
  }

  change() {
    let q = parseInt(this.quantityTarget.value, 10)
    if (!Number.isFinite(q) || q < 1) q = 1
    if (this.availableValue > 0 && q > this.availableValue) q = this.availableValue
    this.quantityTarget.value = q
    this.refresh(q)
  }

  async refresh(q) {
    try {
      const res = await fetch(`${this.urlValue}?quantity=${q}`, { headers: { Accept: "application/json" } })
      if (!res.ok) return
      this.apply(await res.json())
    } catch {
      /* si el servidor no responde, se queda con lo ya mostrado */
    }
  }

  apply(d) {
    if (this.hasQuantityTarget && d.quantity) this.quantityTarget.value = d.quantity
    if (this.hasPriceTarget) this.priceTarget.textContent = d.total_pack

    this.rowTargets.forEach((row, i) => {
      const r = d.rows[i]
      if (!r) return
      const set = (sel, val) => { const el = row.querySelector(sel); if (el) el.textContent = val }
      set('[data-cell="units"]', r.units)
      set('[data-cell="base"]', r.base_total)
      set('[data-cell="pack"]', r.line_total)
      set('[data-cell="saving"]', r.saving)
    })

    if (this.hasTotalBaseTarget) this.totalBaseTarget.textContent = d.total_base
    if (this.hasTotalPackTarget) this.totalPackTarget.textContent = d.total_pack
    if (this.hasTotalSavingTarget) this.totalSavingTarget.textContent = d.total_saving
    if (this.hasNoteTarget) {
      this.noteTarget.textContent = d.saving_note
      this.noteTarget.hidden = !d.has_saving
    }
  }
}
