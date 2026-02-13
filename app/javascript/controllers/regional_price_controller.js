import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['countrySelect', 'comparisonsTable'];

  connect() {
    this.loadComparisons();
  }

  loadComparisons() {
    const selectedCountries = Array.from(this.countrySelectTarget.selectedOptions)
      .map(option => option.value)
      .filter(id => id);

    const params = new URLSearchParams();
    selectedCountries.forEach(id => params.append('country_ids[]', id));

    window.location.href = `/regional-price?${params.toString()}`;
  }
}
