import { Controller } from "@hotwired/stimulus"

// Editor de presupuestos: al cambiar producto o cantidad se aplica el precio
// del escalado; si el precio se toca a mano y no coincide con el escalado se
// muestra un aviso; se pueden añadir y quitar líneas; y el total de cada línea
// y los totales (sin IVA, IVA y con IVA) se recalculan en vivo, descuentos y
// transporte incluidos.
export default class extends Controller {
  static targets = ["line", "linesBody", "template", "shipping", "shippingVat", "shippingWarning", "dtfWarning",
    "shippingCountry", "shippingTotal", "globalDiscount", "totalNet", "totalVat", "totalGross"]

  static values = { products: Object, rates: Object }

  connect() {
    this.visibleLines().forEach((row) => this.refreshWarning(row))
    this.refreshShippingWarning()
    this.renumberPositions()
    this.recalc()
  }

  // --- reordenado por arrastre (desde el asa ⠿) ---

  armDrag(event) {
    event.target.closest("tr").draggable = true
  }

  dragStart(event) {
    this.draggedRow = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver(event) {
    event.preventDefault()
    const row = event.currentTarget
    if (!this.draggedRow || row === this.draggedRow) return

    const rect = row.getBoundingClientRect()
    const before = event.clientY < rect.top + rect.height / 2
    row.parentNode.insertBefore(this.draggedRow, before ? row : row.nextSibling)
  }

  dragEnd(event) {
    event.currentTarget.draggable = false
    this.draggedRow = null
    this.renumberPositions()
    this.recalc()
  }

  // Guarda en cada fila su posición según el orden actual del formulario.
  renumberPositions() {
    this.visibleLines().forEach((row, index) => {
      const position = row.querySelector("[data-role=position]")
      if (position) position.value = index + 1
    })
  }

  addLine() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", Date.now().toString())
    this.linesBodyTarget.insertAdjacentHTML("beforeend", html)
    this.renumberPositions()
    this.recalc()
  }

  // Aplica al campo de transporte el valor calculado con la config de
  // Transporte (base del país + coste/ud. de cada producto), pasado a sin IVA.
  applyShipping() {
    const computed = this.computedShipping()
    if (computed !== null) this.shippingTarget.value = computed.toFixed(2)
    this.refreshShippingWarning()
    this.recalc()
  }

  shippingEdited() {
    this.refreshShippingWarning()
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
    this.renumberPositions()
    this.applyShipping()
  }

  productChanged(event) {
    this.applyTierPrice(event.target.closest("tr"))
    this.applyShipping()
  }

  quantityChanged(event) {
    this.applyTierPrice(event.target.closest("tr"))
    this.applyShipping()
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
    if (this.hasShippingTotalTarget) {
      this.shippingTotalTarget.textContent = isNaN(shipping) ? "—" : this.euros(shipping)
    }
    if (!isNaN(shipping)) {
      net += shipping
      vat += (shipping * (parseFloat(this.shippingVatTarget?.value) || 0)) / 100
    }
    this.totalNetTarget.textContent = this.euros(net)
    this.totalVatTarget.textContent = this.euros(vat)
    this.totalGrossTarget.textContent = this.euros(net + vat)
    this.refreshDtfWarning()
  }

  // Aviso (no bloqueante) si las personalizaciones DTF no coinciden con las
  // fundas del presupuesto (misma regla que el checkout de la tienda).
  refreshDtfWarning() {
    if (!this.hasDtfWarningTarget) return

    let dtf = 0
    let fundas = 0
    this.visibleLines().forEach((row) => {
      const product = this.productData(row)
      const quantity = this.number(row, "quantity")
      if (!product || isNaN(quantity)) return
      dtf += (product.dtf_units || 0) * quantity
      fundas += (product.funda_units || 0) * quantity
    })
    const mismatch = dtf > 0 && dtf !== fundas
    this.dtfWarningTarget.hidden = !mismatch
    if (mismatch) {
      this.dtfWarningTarget.textContent =
        `Aviso: el presupuesto lleva ${dtf} personalizaciones DTF y ${fundas} fundas; deberían coincidir.`
    }
  }

  // --- utilidades ---

  visibleLines() {
    return this.lineTargets.filter((row) => !row.hidden)
  }

  // Transporte sin IVA según la config de Transporte, o null si no hay datos.
  computedShipping() {
    const base = this.ratesValue[this.shippingCountryTarget?.value] ?? this.ratesValue["España (Península)"]
    if (base === undefined) return null

    let gross = base
    this.visibleLines().forEach((row) => {
      const product = this.productData(row)
      const quantity = this.number(row, "quantity")
      if (product && !isNaN(quantity)) gross += product.shipping_unit * quantity
    })
    const vat = parseFloat(this.shippingVatTarget?.value) || 0
    return Math.round((gross / (1 + vat / 100)) * 100) / 100
  }

  refreshShippingWarning() {
    if (!this.hasShippingWarningTarget) return

    const computed = this.computedShipping()
    const manual = parseFloat(this.shippingTarget?.value)
    const differs = computed !== null && !isNaN(manual) && Math.abs(manual - computed) > 0.005
    this.shippingWarningTarget.hidden = !differs
    if (differs) this.shippingWarningTarget.textContent = `⚠ No coincide con el transporte calculado (${computed.toFixed(2)} €)`
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
