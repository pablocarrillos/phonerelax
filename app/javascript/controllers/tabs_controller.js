import { Controller } from "@hotwired/stimulus"

// Pestañas simples: al pulsar un botón se muestra su panel y se ocultan los demás.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.tabTargets.forEach((tab, i) => tab.classList.toggle("active", i === index))
    this.panelTargets.forEach((panel, i) => (panel.hidden = i !== index))
  }
}
