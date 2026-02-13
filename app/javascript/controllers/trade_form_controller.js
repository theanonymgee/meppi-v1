// app/javascript/controllers/trade_form_controller.js
// Stimulus 컨트롤러 - 거래 폼 유효성 검증
import { Controller } from "@hotwired/stimulus";

export default class extends(Controller {
  static targets = ["form", "price", "area", "rooms"];
  static classes = ["error"];

  // 유효성 검증 범위 (constants)
  VALIDATIONS = {
    price: { min: 0, max: 100000000, name: "가격" },
    area: { min: 1, max: 1000, name: "면적" },
    rooms: { min: 1, max: 50, name: "방수" }
  };

  connect() {
    // 폼 제어 시작
    this.setupRealTimeValidation();
  }

  setupRealTimeValidation() {
    // 실시간 유효성 검증 설정
    this.priceTarget.addEventListener("input", () => this.validateField("price"));
    this.areaTarget.addEventListener("input", () => this.validateField("area"));
    this.roomsTarget.addEventListener("input", () => this.validateField("rooms"));
  }

  validateField(fieldName) {
    const target = this[`${fieldName}Target`];
    const value = this.parseValue(target.value);
    const validation = VALIDATIONS[fieldName];

    if (!this.isValid(value, validation)) {
      this.showError(fieldName, validation);
    } else {
      this.clearError(fieldName);
    }
  }

  parseValue(value) {
    // 숫자 파싱
    const num = parseFloat(value);
    return isNaN(num) ? null : num;
  }

  isValid(value, validation) {
    if (value === null || value === "") return false;
    return value >= validation.min && value <= validation.max;
  }

  showError(fieldName, validation) {
    const errorElement = this.element.querySelector(`[data-error="${fieldName}"]`);
    if (!errorElement) return;

    errorElement.textContent = `${validation.name}은(는) ${validation.min.toLocaleString()} ~ ${validation.max.toLocaleString()} ${validation.name} 사이여야 합니다.`;
    errorElement.classList.remove("hidden");
  }

  clearError(fieldName) {
    const errorElement = this.element.querySelector(`[data-error="${fieldName}"]`);
    if (errorElement) {
      errorElement.classList.add("hidden");
    }
  }
}
