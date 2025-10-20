import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="comment-animation"
export default class extends Controller {
  connect() {
    // 追加時のアニメーション（新規コメントが prepend された時）
    this.element.classList.add('comment-enter')

    // アニメーション終了後にクラスを削除（再利用可能にするため）
    this.element.addEventListener('animationend', () => {
      this.element.classList.remove('comment-enter')
    }, { once: true })
  }

  // 編集完了時のハイライト
  highlight() {
    this.element.classList.add('comment-highlight')
    setTimeout(() => {
      this.element.classList.remove('comment-highlight')
    }, 1000)
  }

  // Turbo Stream の remove アクションをインターセプト
  beforeStreamRender(event) {
    // remove アクションのみをインターセプト
    if (event.target.getAttribute('action') === 'remove' &&
        event.target.getAttribute('target') === this.element.id) {
      // デフォルトの削除を防ぐ
      event.preventDefault()

      // アニメーションクラスを追加
      this.element.classList.add('comment-removing')

      // アニメーション完了後に要素を削除
      setTimeout(() => {
        this.element.remove()
      }, 300)
    }
  }
}
