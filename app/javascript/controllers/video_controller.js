import { Controller } from "@hotwired/stimulus"

// Bloque de vídeo con portada: al pulsar el play se carga el iframe de YouTube.
export default class extends Controller {
  static values = { id: String }

  play() {
    const iframe = document.createElement("iframe")
    iframe.src = `https://www.youtube.com/embed/${this.idValue}?autoplay=1`
    iframe.allow = "autoplay; encrypted-media"
    iframe.allowFullscreen = true
    this.element.replaceChildren(iframe)
  }
}
