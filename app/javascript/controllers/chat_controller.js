import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messages", "input"]

  connect() {
    this.subscription = consumer.subscriptions.create("ChatChannel", {
      received: (data) => this.appendMessage(data)
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message || !this.subscription) return

    this.subscription.perform("speak", { message })
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  appendMessage({ message, sent_at: sentAt, user_name: userName }) {
    if (!message) return

    const entry = document.createElement("div")
    entry.className = "chat__message"

    const time = this.buildTimestamp(sentAt)
    entry.appendChild(time)

    const speaker = document.createElement("span")
    speaker.className = "chat__speaker"
    speaker.textContent = userName || "Guest"
    entry.appendChild(speaker)

    const body = document.createElement("span")
    body.className = "chat__body"
    body.textContent = message

    entry.appendChild(body)
    this.messagesTarget.appendChild(entry)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  buildTimestamp(sentAt) {
    const timeElement = document.createElement("time")
    timeElement.className = "chat__timestamp"

    const time = sentAt ? new Date(sentAt) : new Date()
    timeElement.dateTime = time.toISOString()
    timeElement.textContent = time.toLocaleTimeString()

    return timeElement
  }
}
