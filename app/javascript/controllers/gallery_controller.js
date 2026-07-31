import { Controller } from "@hotwired/stimulus"

// Galería de la ficha de producto: las miniaturas cambian la imagen principal.
export default class extends Controller {
  static targets = ["main", "thumb"]

  show(event) {
    this.mainTarget.src = event.params.url
    this.thumbTargets.forEach(thumb => thumb.classList.toggle("active", thumb === event.currentTarget))
  }
}
