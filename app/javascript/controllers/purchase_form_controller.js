import { Controller } from "@hotwired/stimulus"

// Formulario de compra: calcula en vivo el total de cada línea (unidades ×
// coste + transporte + aduanas + otros) y los totales por concepto y de la
// factura, en la moneda seleccionada. Si la compra es en dólares y ya tiene
// tipo de cambio fijado, cada total muestra también su equivalente en euros.
export default class extends Controller {
  static targets = ["currency", "line", "totalShipping", "totalCustoms", "totalOther", "totalInvoice"]
  static values = { rate: Number }

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
      if (cell) { if (hasProduct && filled) { this.render(cell, total, sym) } else { cell.textContent = "—" } }

      if (hasProduct) { tShip += ship; tCust += cust; tOther += other; tInv += total }
    })

    if (this.hasTotalShippingTarget) this.render(this.totalShippingTarget, tShip, sym)
    if (this.hasTotalCustomsTarget) this.render(this.totalCustomsTarget, tCust, sym)
    if (this.hasTotalOtherTarget) this.render(this.totalOtherTarget, tOther, sym)
    if (this.hasTotalInvoiceTarget) this.render(this.totalInvoiceTarget, tInv, sym)
  }

  // Pinta el importe en la moneda de la compra y, en dólares con tipo de cambio
  // conocido, también en euros. NBSP + nowrap: el símbolo nunca salta de línea.
  render(cell, n, sym) {
    let html = `<span style="white-space:nowrap">${this.num(n)} ${sym}</span>`
    if (sym === "$" && this.rateValue > 0) html += ` <span class="dual-eur">(${this.num(n * this.rateValue)} €)</span>`
    cell.innerHTML = html
  }

  num(n) {
    return n.toLocaleString("es-ES", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
