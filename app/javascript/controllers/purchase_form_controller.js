import { Controller } from "@hotwired/stimulus"

// Formulario de compra: calcula en vivo el total de cada línea (unidades ×
// coste + transporte + aduanas + otros) y los totales por concepto y de la
// factura, en la moneda seleccionada. La conversión a euros se fija al guardar.
export default class extends Controller {
  static targets = ["currency", "line", "totalShipping", "totalCustoms", "totalOther", "totalInvoice"]

  connect() { this.recalc() }

  recalc() {
    const sym = this.hasCurrencyTarget && this.currencyTarget.value === "USD" ? "$" : "€"
    let tShip = 0, tCust = 0, tOther = 0, tInv = 0

    this.lineTargets.forEach((row) => {
      const num = (field) => {
        const el = row.querySelector(`[data-field="${field}"]`)
        return el ? parseFloat(el.value) || 0 : 0
      }
      const qty = num("quantity")
      const unit = num("unit_cost")
      const ship = num("shipping_cost")
      const cust = num("customs_cost")
      const other = num("other_costs")
      const select = row.querySelector("select")
      const hasProduct = select && select.value !== ""
      const filled = qty || unit || ship || cust || other
      const total = qty * unit + ship + cust + other

      const cell = row.querySelector("[data-line-total]")
      if (cell) cell.textContent = hasProduct && filled ? this.fmt(total, sym) : "—"

      if (hasProduct) { tShip += ship; tCust += cust; tOther += other; tInv += total }
    })

    if (this.hasTotalShippingTarget) this.totalShippingTarget.textContent = this.fmt(tShip, sym)
    if (this.hasTotalCustomsTarget) this.totalCustomsTarget.textContent = this.fmt(tCust, sym)
    if (this.hasTotalOtherTarget) this.totalOtherTarget.textContent = this.fmt(tOther, sym)
    if (this.hasTotalInvoiceTarget) this.totalInvoiceTarget.textContent = this.fmt(tInv, sym)
  }

  fmt(n, sym) {
    return `${n.toLocaleString("es-ES", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${sym}`
  }
}
