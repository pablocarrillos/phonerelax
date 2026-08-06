import { Controller } from "@hotwired/stimulus"

// Escalado de un producto: sin IVA, con IVA y descuento sincronizados.
// El descuento es respecto al precio sin IVA del PRIMER tramo, así que al
// editar el tramo base se recalculan los descuentos de todas las filas.
// Solo el precio sin IVA viaja en el formulario. «Añadir tramo» clona la
// fila plantilla con un índice único para poder crear tantos como se quiera.
export default class extends Controller {
  static targets = ["row", "tbody", "template"]
  static values = { rate: Number }

  addRow() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now())
    this.tbodyTarget.insertAdjacentHTML("beforeend", html)
  }

  fromNet(event) {
    const row = event.target.closest("tr")
    const net = this.value(row, "net")
    this.set(row, "gross", isNaN(net) ? "" : (net * this.factor()).toFixed(2))
    this.refreshDiscounts()
  }

  fromGross(event) {
    const row = event.target.closest("tr")
    const gross = this.value(row, "gross")
    this.set(row, "net", isNaN(gross) ? "" : (gross / this.factor()).toFixed(2))
    this.refreshDiscounts()
  }

  fromDiscount(event) {
    const row = event.target.closest("tr")
    const pct = this.value(row, "discount")
    const base = this.basePrice()
    if (isNaN(pct) || !(base > 0)) return

    const net = base * (1 - pct / 100)
    this.set(row, "net", net.toFixed(2))
    this.set(row, "gross", (net * this.factor()).toFixed(2))
  }

  // --- utilidades ---

  factor() {
    return 1 + (this.rateValue || 0) / 100
  }

  // Precio sin IVA del primer tramo: la base de los descuentos.
  basePrice() {
    return this.value(this.rowTargets[0], "net")
  }

  refreshDiscounts() {
    const base = this.basePrice()
    this.rowTargets.forEach((row, index) => {
      const discount = row.querySelector("[data-role=discount]")
      if (!discount || index === 0) return

      const net = this.value(row, "net")
      discount.value = !isNaN(net) && base > 0 ? (100 * (1 - net / base)).toFixed(1) : ""
    })
  }

  value(row, role) {
    return parseFloat(row?.querySelector(`[data-role=${role}]`)?.value)
  }

  set(row, role, newValue) {
    const input = row.querySelector(`[data-role=${role}]`)
    if (input) input.value = newValue
  }
}
