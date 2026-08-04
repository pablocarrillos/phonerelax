import { Controller } from "@hotwired/stimulus"

// Bloque de factura del checkout: muestra/oculta los datos fiscales según la
// casilla "Necesito factura", permite copiar la dirección de envío y comprueba
// en vivo el NIF-IVA europeo contra VIES.
export default class extends Controller {
  static targets = ["checkbox", "fields", "taxId", "viesStatus"]
  static values = { viesUrl: String }

  connect() { this.toggle() }

  // Enseña u oculta los datos fiscales y marca sus campos como obligatorios solo
  // cuando se pide factura.
  toggle() {
    const on = this.checkboxTarget.checked
    this.fieldsTarget.hidden = !on
    this.fieldsTarget.querySelectorAll("[data-required]").forEach((el) => { el.required = on })
    if (!on) this.clearVies()
  }

  // Copia la dirección de envío en los campos fiscales al marcar la casilla.
  copyShipping(event) {
    if (!event.target.checked) return
    const form = this.element.closest("form") || this.element
    const map = { tax_address: "address", tax_city: "city", tax_postal_code: "postal_code", tax_province: "province", tax_country: "country" }
    for (const [tax, ship] of Object.entries(map)) {
      const src = form.querySelector(`[name="order[${ship}]"]`)
      const dst = form.querySelector(`[name="order[${tax}]"]`)
      if (src && dst) dst.value = src.value
    }
  }

  clearVies() {
    if (this.hasViesStatusTarget) { this.viesStatusTarget.textContent = ""; this.viesStatusTarget.className = "vies-status" }
  }

  // Comprueba el NIF-IVA en VIES. Solo para identificadores europeos (empiezan
  // por el código de país); un NIF/CIF español no se consulta.
  async checkVies() {
    if (!this.hasViesStatusTarget) return
    const raw = (this.taxIdTarget.value || "").trim()
    const ds = this.viesStatusTarget.dataset
    if (raw.length < 4 || !/^[A-Za-z]{2}/.test(raw)) { this.clearVies(); return }

    this.viesStatusTarget.textContent = ds.checking || "…"
    this.viesStatusTarget.className = "vies-status"
    try {
      const res = await fetch(`${this.viesUrlValue}?vat=${encodeURIComponent(raw)}`, { headers: { Accept: "application/json" } })
      const data = await res.json()
      if (data.valid === true) {
        this.viesStatusTarget.textContent = (ds.ok || "OK") + (data.name ? ` · ${data.name}` : "")
        this.viesStatusTarget.className = "vies-status ok"
      } else if (data.valid === false) {
        this.viesStatusTarget.textContent = ds.ko || "NIF-IVA no válido"
        this.viesStatusTarget.className = "vies-status ko"
      } else {
        this.viesStatusTarget.textContent = ds.unavailable || ""
        this.viesStatusTarget.className = "vies-status"
      }
    } catch {
      this.viesStatusTarget.textContent = ds.unavailable || ""
      this.viesStatusTarget.className = "vies-status"
    }
  }
}
