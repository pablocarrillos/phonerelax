import { Controller } from "@hotwired/stimulus"

// Bloque de factura del checkout: muestra/oculta los datos fiscales según la
// casilla "Necesito factura", permite copiar la dirección de envío, comprueba
// en vivo el NIF-IVA europeo contra VIES y alterna el resumen entre precios
// con IVA y sin IVA cuando la venta queda exenta (envío a Canarias o entrega
// intracomunitaria B2B con VIES válido). El resultado real lo fija el servidor
// en Order#apply_vat_exemption!; esto es su espejo visual.
export default class extends Controller {
  static targets = ["checkbox", "fields", "taxId", "viesStatus", "country", "amount", "totalLabel", "exemptNote"]
  static values = { viesUrl: String }

  connect() {
    this.viesValid = null
    this.toggle()
  }

  // Enseña u oculta los datos fiscales y marca sus campos como obligatorios solo
  // cuando se pide factura.
  toggle() {
    const on = this.checkboxTarget.checked
    this.fieldsTarget.hidden = !on
    this.fieldsTarget.querySelectorAll("[data-required]").forEach((el) => { el.required = on })
    if (!on) this.clearVies()
    this.refresh()
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
    this.viesValid = null
    if (this.hasViesStatusTarget) { this.viesStatusTarget.textContent = ""; this.viesStatusTarget.className = "vies-status" }
    this.refresh()
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
        this.viesValid = true
      } else if (data.valid === false) {
        this.viesStatusTarget.textContent = ds.ko || "NIF-IVA no válido"
        this.viesStatusTarget.className = "vies-status ko"
        this.viesValid = false
      } else {
        this.viesStatusTarget.textContent = ds.unavailable || ""
        this.viesStatusTarget.className = "vies-status"
        this.viesValid = null
      }
    } catch {
      this.viesStatusTarget.textContent = ds.unavailable || ""
      this.viesStatusTarget.className = "vies-status"
      this.viesValid = null
    }
    this.refresh()
  }

  // "export", "intra" o null: espejo de Order#apply_vat_exemption! (Canarias
  // exporta para cualquier cliente; intracomunitaria solo B2B con NIF-IVA de
  // otro país UE validado en VIES y envío fuera de España).
  exemption() {
    const country = this.hasCountryTarget ? this.countryTarget.value : ""
    if (country === "España (Canarias)") return "export"

    const vat = this.hasTaxIdTarget ? (this.taxIdTarget.value || "").trim().toUpperCase() : ""
    const foreignVat = /^[A-Z]{2}/.test(vat) && !vat.startsWith("ES")
    if (this.checkboxTarget.checked && this.viesValid === true && foreignVat && !country.startsWith("España")) return "intra"

    return null
  }

  // Pinta el resumen con la variante con o sin IVA y la nota de exención.
  refresh() {
    const mode = this.exemption()
    const key = mode ? "net" : "gross"
    this.amountTargets.forEach((el) => { el.textContent = el.dataset[key] })
    if (this.hasTotalLabelTarget) this.totalLabelTarget.textContent = this.totalLabelTarget.dataset[key]
    if (this.hasExemptNoteTarget) {
      this.exemptNoteTarget.hidden = !mode
      if (mode) this.exemptNoteTarget.textContent = mode === "export" ? this.exemptNoteTarget.dataset.export : this.exemptNoteTarget.dataset.intra
    }
  }
}
