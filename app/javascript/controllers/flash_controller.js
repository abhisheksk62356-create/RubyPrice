import { Controller } from "@hotwired/stimulus"

// Auto-dismisses flash notices/alerts after a few seconds.
export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.element.classList.add("transition", "duration-300", "ease-in", "opacity-0")
      setTimeout(() => this.element.remove(), 300)
    }, 4000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
