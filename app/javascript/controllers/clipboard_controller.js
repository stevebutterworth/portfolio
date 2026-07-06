import { Controller } from "@hotwired/stimulus"

// Copies the markdown CV from data-clipboard-text to the clipboard and briefly
// confirms the copy by swapping the button label to "Copied".
export default class extends Controller {
  static targets = ["label"]

  copy() {
    navigator.clipboard.writeText(this.element.dataset.clipboardText).then(() => this.confirm())
  }

  confirm() {
    const label = this.labelTarget
    const original = label.textContent
    label.textContent = "Copied"
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => { label.textContent = original }, 1500)
  }
}
