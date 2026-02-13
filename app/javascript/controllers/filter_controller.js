// Filter Controller - Dynamic filtering for data tables
// Handles multi-select filters for countries, brands, channels
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "form"]
  static values = {
    autoSubmit: { type: Boolean, default: false }
  }

  filter() {
    if (this.autoSubmitValue) {
      this.submit()
    }
    // If not auto-submit, the user will need to click the submit button manually
  }

  submit() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  reset() {
    if (this.hasFormTarget) {
      this.formTarget.reset()
      this.formTarget.requestSubmit()
    }
  }
}
