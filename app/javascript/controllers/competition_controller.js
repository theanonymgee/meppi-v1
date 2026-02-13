import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['countrySelect', 'marketData'];
  static values = {
    countryId: String
  };

  connect() {
    this.loadMarketData();
  }

  loadMarketData() {
    const countryId = this.countryIdValue;

    const params = new URLSearchParams();
    if (countryId) {
      params.append('country_id', countryId);
    }

    window.location.href = `/competition?${params.toString()}`;
  }
}
