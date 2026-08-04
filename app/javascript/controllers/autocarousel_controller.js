import { Controller } from "@hotwired/stimulus"

// Carrusel automático sin controles: rota las imágenes de la galería cada 3 s.
// Con una sola imagen no hace nada.
export default class extends Controller {
  static targets = ["slide"]

  connect() {
    if (this.slideTargets.length < 2) return
    this.index = 0
    this.timer = setInterval(() => this.advance(), 3000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  advance() {
    this.index = (this.index + 1) % this.slideTargets.length
    this.slideTargets.forEach((slide, i) => slide.classList.toggle("active", i === this.index))
  }
}
