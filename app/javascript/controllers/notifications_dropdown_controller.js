import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    this.boundHandleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleOutsideClick)
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.dropdownTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    // 次のフレームでイベントリスナーを追加（現在のクリックイベントが完了した後）
    requestAnimationFrame(() => {
      document.addEventListener("click", this.boundHandleOutsideClick)
      document.addEventListener("keydown", this.boundHandleEscape)
    })
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundHandleOutsideClick)
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
