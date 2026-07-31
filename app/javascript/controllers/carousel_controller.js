import { Controller } from "@hotwired/stimulus"

// Carrusel del hero: avanza solo cada 5 s, con flechas y puntos como en phonerelax.com.
export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.show(0)
    this.play()
  }

  disconnect() { this.stop() }

  next() { this.show(this.indexValue + 1); this.restart() }
  prev() { this.show(this.indexValue - 1); this.restart() }
  go(event) { this.show(Number(event.params.index)); this.restart() }

  show(index) {
    const count = this.slideTargets.length
    this.indexValue = ((index % count) + count) % count
    this.slideTargets.forEach((slide, i) => slide.classList.toggle("active", i === this.indexValue))
    this.dotTargets.forEach((dot, i) => dot.classList.toggle("active", i === this.indexValue))
  }

  play() { this.timer = setInterval(() => this.show(this.indexValue + 1), 5000) }
  stop() { clearInterval(this.timer) }
  restart() { this.stop(); this.play() }
}
