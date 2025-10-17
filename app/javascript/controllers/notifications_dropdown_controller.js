import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleOutsideClick)
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
    // 次のイベントループで外側クリックのリスナーを追加
    setTimeout(() => {
      document.addEventListener("click", this.boundHandleOutsideClick)
    }, 0)
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundHandleOutsideClick)
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
