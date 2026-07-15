import { Controller } from "@hotwired/stimulus"

// Assembles a mailto link on connect, so the full address never appears in
// the HTML source where scrapers can harvest it. With label set, also swaps
// the server-rendered "[at]" fallback text for the real address.
export default class extends Controller {
  static values = { user: String, domain: String, label: Boolean }

  connect() {
    const address = `${this.userValue}@${this.domainValue}`
    this.element.href = `mailto:${address}`
    if (this.labelValue) this.element.textContent = address
  }
}
