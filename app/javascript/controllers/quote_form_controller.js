import { Controller } from "@hotwired/stimulus"

// Editor de presupuestos: al cambiar producto o cantidad se aplica el precio
// del escalado; si el precio se toca a mano y no coincide con el escalado se
// muestra un aviso; y los totales (sin IVA, IVA y con IVA) se recalculan en
// vivo, transporte incluido.
export default class extends Controller {
  static targets = ["line", "shipping", "shippingVat", "totalNet", "totalVat", "totalGross"]
  static values = { products: Object }

  connect() {
    this.lineTargets.forEach((row) => this.refreshWarning(row))
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
    let net = 0
    let vat = 0
    this.lineTargets.forEach((row) => {
      const quantity = this.number(row, "quantity")
      const price = this.number(row, "price")
      if (isNaN(quantity) || isNaN(price)) return

      const lineTotal = quantity * price
      net += lineTotal
      vat += (lineTotal * (this.number(row, "vat") || 0)) / 100
    })
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
