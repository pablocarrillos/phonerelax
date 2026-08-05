import { Controller } from "@hotwired/stimulus"

// Lista reordenable arrastrando por el asa (⠿): al soltar, envía el nuevo
// orden de ids al servidor y renumera la columna de posición. El arrastre solo
// se activa desde el asa para no interferir con enlaces y botones de la fila.
export default class extends Controller {
  static targets = ["row"]
  static values = { url: String }

  armDrag(event) { event.target.closest("tr").draggable = true }

  dragStart(event) {
    const row = event.target.closest("tr")
    if (!row.draggable) { event.preventDefault(); return }
    this.dragged = row
    row.classList.add("dragging")
    event.dataTransfer.effectAllowed = "move"
    try { event.dataTransfer.setData("text/plain", "") } catch { /* IE/Safari antiguos */ }
  }

  dragOver(event) {
    event.preventDefault()
    const over = event.target.closest("tr")
    if (!this.dragged || !over || over === this.dragged) return
    const rows = this.rowTargets
    const from = rows.indexOf(this.dragged)
    const to = rows.indexOf(over)
    if (from < 0 || to < 0) return
    over.parentNode.insertBefore(this.dragged, from < to ? over.nextSibling : over)
  }

  dragEnd() {
    if (!this.dragged) return
    this.dragged.classList.remove("dragging")
    this.dragged.draggable = false
    this.dragged = null
    this.renumber()
    this.persist()
  }

  renumber() {
    this.rowTargets.forEach((row, index) => {
      const cell = row.querySelector("[data-role='position']")
      if (cell) cell.textContent = index + 1
    })
  }

  async persist() {
    const ids = this.rowTargets.map((row) => row.dataset.id)
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const res = await fetch(this.urlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token, Accept: "application/json" },
        body: JSON.stringify({ ids: ids })
      })
      this.element.classList.toggle("reorder-error", !res.ok)
    } catch {
      this.element.classList.add("reorder-error")
    }
  }
}
