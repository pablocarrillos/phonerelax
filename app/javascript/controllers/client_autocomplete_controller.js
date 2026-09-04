import { Controller } from "@hotwired/stimulus"

// Autocompletado de cliente en el formulario de presupuestos: al escribir 3+
// letras sugiere clientes existentes; al elegir uno se fija el client_id. Si el
// texto no corresponde a un cliente elegido, client_id queda vacío (el servidor
// exige que el cliente exista para crear el presupuesto).
export default class extends Controller {
  static targets = ["input", "id", "list"]
  static values = { url: String }

  connect() { this.index = -1 }

  // Al teclear se pierde la selección anterior y se buscan coincidencias.
  onInput() {
    this.idTarget.value = ""
    this.query()
  }

  onFocus() {
    if (this.inputTarget.value.trim().length >= 3) this.query()
  }

  // Retraso para que el click en una sugerencia se registre antes de ocultar.
  onBlur() {
    setTimeout(() => this.hide(), 150)
  }

  async query() {
    const term = this.inputTarget.value.trim()
    if (term.length < 3) return this.hide()

    try {
      const res = await fetch(`${this.urlValue}?q=${encodeURIComponent(term)}`, { headers: { Accept: "application/json" } })
      if (!res.ok) return this.hide()
      this.render(await res.json())
    } catch {
      this.hide()
    }
  }

  render(clients) {
    this.listTarget.innerHTML = ""
    this.index = -1

    if (!clients.length) {
      const li = document.createElement("li")
      li.className = "autocomplete-empty"
      li.textContent = "Sin coincidencias"
      this.listTarget.appendChild(li)
    } else {
      clients.forEach((c) => {
        const li = document.createElement("li")
        li.className = "autocomplete-item"
        li.textContent = c.name
        li.dataset.id = c.id
        li.dataset.name = c.name
        li.dataset.email = c.email || ""
        li.dataset.phone = c.phone || ""
        li.dataset.address = c.address || ""
        li.addEventListener("mousedown", (e) => { e.preventDefault(); this.chooseEl(li) })
        this.listTarget.appendChild(li)
      })
    }
    this.listTarget.hidden = false
  }

  chooseEl(el) {
    this.idTarget.value = el.dataset.id
    this.inputTarget.value = el.dataset.name
    // Precarga los datos de la ficha del cliente en el presupuesto, sin pisar
    // nada que ya esté escrito (al editar, o si se cambia de cliente a medias).
    this.fill("quote_contact_email", el.dataset.email)
    this.fill("quote_contact_phone", el.dataset.phone)
    this.fill("quote_delivery_address", el.dataset.address)
    this.hide()
  }

  fill(fieldId, value) {
    const field = document.getElementById(fieldId)
    if (field && !field.value.trim() && value) field.value = value
  }

  onKeydown(e) {
    if (this.listTarget.hidden) return
    const items = Array.from(this.listTarget.querySelectorAll(".autocomplete-item"))
    if (!items.length) return

    if (e.key === "ArrowDown") {
      e.preventDefault()
      this.index = Math.min(this.index + 1, items.length - 1)
      this.highlight(items)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this.index = Math.max(this.index - 1, 0)
      this.highlight(items)
    } else if (e.key === "Enter" && this.index >= 0) {
      e.preventDefault()
      this.chooseEl(items[this.index])
    } else if (e.key === "Escape") {
      this.hide()
    }
  }

  highlight(items) {
    items.forEach((el, i) => el.classList.toggle("active", i === this.index))
  }

  hide() {
    this.listTarget.hidden = true
  }
}
