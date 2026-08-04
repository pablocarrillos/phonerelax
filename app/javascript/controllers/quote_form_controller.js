import { Controller } from "@hotwired/stimulus"

// Editor de presupuestos: al cambiar producto o cantidad se aplica el precio
// del escalado; si el precio se toca a mano y no coincide con el escalado se
// muestra un aviso; se pueden añadir y quitar líneas; y el total de cada línea
// y los totales (sin IVA, IVA y con IVA) se recalculan en vivo, descuentos y
// transporte incluidos.
export default class extends Controller {
  static targets = ["line", "linesBody", "template", "shipping", "shippingVat",
    "globalDiscount", "totalNet", "totalVat", "totalGross"]

  static values = { products: Object }

  connect() {
    this.visibleLines().forEach((row) => this.refreshWarning(row))
    this.recalc()
  }

  addLine() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now().toString())
    this.linesBodyTarget.insertAdjacentHTML("beforeend", html)
    this.recalc()
  }

  // Quita la fila: las guardadas se marcan para borrar (_destroy) y se ocultan;
  // las nuevas se eliminan del formulario sin más.
  removeLine(event) {
    const row = event.target.closest("tr")
    const destroy = row.querySelector("[data-role=destroy]")
    if (destroy) {
      destroy.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.recalc()
  }

  productChanged(event) {
    const row = event.target.closest("tr")
    const description = row.querySelector("[data-role=description]")
    const product = this.productData(row)
    if (product && description && !description.value) description.value = product.name
    this.applyTierPrice(row)
  }

  quantityChanged(event) {
    this.applyTierPrice(event.target.closest("tr"))
  }

  priceEdited(event) {
    this.refreshWarning(event.target.closest("tr"))
    this.recalc()
  }

  recalc() {
    let linesTotal = 0
    let linesVat = 0
    this.visibleLines().forEach((row) => {
      const total = this.lineTotal(row)
      const cell = row.querySelector("[data-role=line-total]")
      if (cell) cell.textContent = total === null ? "—" : this.euros(total)
      if (total === null) return

      linesTotal += total
      linesVat += (total * (this.number(row, "vat") || 0)) / 100
    })
    const globalFactor = 1 - (parseFloat(this.globalDiscountTarget?.value) || 0) / 100
    let net = linesTotal * globalFactor
    let vat = linesVat * globalFactor
    const shipping = parseFloat(this.shippingTarget?.value)
    if (!isNaN(shipping)) {
      net += shipping
      vat += (shipping * (parseFloat(this.shippingVatTarget?.value) || 0)) / 100
    }
    this.totalNetTarget.textContent = this.euros(net)
    this.totalVatTarget.textContent = this.euros(vat)
    this.totalGrossTarget.textContent = this.euros(net + vat)
  }

  // --- utilidades ---

  visibleLines() {
    return this.lineTargets.filter((row) => !row.hidden)
  }

  // Total de la fila (uds. × precio × descuento de línea), o null si está incompleta.
  lineTotal(row) {
    const quantity = this.number(row, "quantity")
    const price = this.number(row, "price")
    if (isNaN(quantity) || isNaN(price)) return null

    const discount = 1 - (this.number(row, "discount") || 0) / 100
    return Math.round(quantity * price * discount * 100) / 100
  }

  applyTierPrice(row) {
    const expected = this.tierPrice(row)
    if (expected !== null) {
      const price = row.querySelector("[data-role=price]")
      price.value = expected.toFixed(4)
    }
    this.refreshWarning(row)
    this.recalc()
  }

  // Precio del escalado para el producto y cantidad de la fila (o null).
  tierPrice(row) {
    const product = this.productData(row)
    const quantity = this.number(row, "quantity")
    if (!product || isNaN(quantity)) return null

    let price = null
    for (const [min, tierPrice] of product.tiers) {
      if (quantity >= min) price = tierPrice
    }
    return price
  }

  refreshWarning(row) {
    const warning = row.querySelector("[data-role=warning]")
    if (!warning) return

    const expected = this.tierPrice(row)
    const price = this.number(row, "price")
    const differs = expected !== null && !isNaN(price) && Math.abs(price - expected) > 0.0001
    warning.hidden = !differs
    if (differs) warning.textContent = `⚠ No coincide con el escalado (${expected.toFixed(4)} €)`
  }

  productData(row) {
    const select = row.querySelector("[data-role=product]")
    return select?.value ? this.productsValue[select.value] : null
  }

  number(row, role) {
    return parseFloat(row.querySelector(`[data-role=${role}]`)?.value)
  }

  euros(amount) {
    return amount.toLocaleString("es-ES", { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + " €"
  }
}
