import { Controller } from "@hotwired/stimulus"

// Ficha de un producto con escalado de precios: al cambiar la cantidad enseña
// en vivo el unitario del tramo alcanzado, el total y el descuento frente al
// precio base. Todo en cliente: los tramos van embebidos en la página.
export default class extends Controller {
  static targets = ["quantity", "price", "live"]
  static values = { tiers: Array, base: Number, totalTemplate: String, discountTemplate: String }

  change() {
    let q = parseInt(this.quantityTarget.value, 10)
    if (!Number.isFinite(q) || q < 1) { q = 1; this.quantityTarget.value = q }

    const unit = this.unitFor(q)
    this.priceTarget.textContent = this.money(unit)

    const pct = Math.round((1 - unit / this.baseValue) * 100)
    if (q > 1 || pct > 0) {
      let text = this.totalTemplateValue
        .replace("%{total}", this.money(Math.round(unit * q * 100) / 100))
        .replace("%{units}", q)
      if (pct > 0) text += " · " + this.discountTemplateValue.replace("%{pct}", pct)
      this.liveTarget.textContent = text
      this.liveTarget.hidden = false
    } else {
      this.liveTarget.hidden = true
    }
  }

  unitFor(q) {
    let unit = this.baseValue
    for (const tier of this.tiersValue) if (q >= tier.min) unit = tier.unit
    return unit
  }

  money(v) {
    const lang = document.documentElement.lang || "es"
    return new Intl.NumberFormat(lang, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v) + " €"
  }
}
