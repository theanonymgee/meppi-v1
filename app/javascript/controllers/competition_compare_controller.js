import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['phoneSelect', 'comparisonTable', 'insights'];
  static values = {
    minPhones: Number,
    maxPhones: Number
  };

  connect() {
    this.minPhonesValue = 2;
    this.maxPhonesValue = 4;

    this.phoneSelectTarget.addEventListener('change', this.validateSelection.bind(this));
  }

  validateSelection() {
    const selected = Array.from(this.phoneSelectTarget.selectedOptions);
    const count = selected.length;

    if (count > 0 || count < this.minPhonesValue || count > this.maxPhonesValue) {
      this.phoneSelectTarget.setCustomValidity(
        `Please select between ${this.minPhonesValue} and ${this.maxPhonesValue} phones`
      );
    } else {
      this.phoneSelectTarget.setCustomValidity('');
    }
  }
}
