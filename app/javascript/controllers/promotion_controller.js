import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['countrySelect', 'brandSelect', 'promotionsList'];
  static values = {
    countryId: String,
    brandId: String
  };

  connect() {
    this.loadPromotions();
  }

  loadPromotions() {
    const params = new URLSearchParams();

    if (this.countryIdValue) {
      params.append('country_id', this.countryIdValue);
    }

    if (this.brandIdValue) {
      params.append('brand_id', this.brandIdValue);
    }

    const url = params.toString() ? `/promotion?${params.toString()}` : '/promotion';
    window.location.href = url;
  }

  filterByCountry(event) {
    this.countryIdValue = event.target.value;
    this.loadPromotions();
  }

  filterByBrand(event) {
    this.brandIdValue = event.target.value;
    this.loadPromotions();
  }
}
