import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-on-cmd-enter"
export default class extends Controller {
  static targets = ["textarea"]

  handleKeydown(event) {
    // Command-Enter (Mac) または Ctrl-Enter (Windows/Linux) でフォーム送信
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}
