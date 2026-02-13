// app/javascript/controllers/notification_controller.js
// Stimulus 컨트롤러 - 알림 메시지 자동 제거
import { Controller } from "@hotwired/stimulus";

export default class extends(Controller {
  static targets = ["container"];
  static values = {
    duration: { type: Number, default: 3000 } // 3초
  };

  connect() {
    // 커넥트 연결 시 자동 제거 예약
    this.dismissTimer = setTimeout(() => this.dismiss(), this.durationValue);
  }

  disconnect() {
    // 커넥트 해제 시 정리
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer);
    }
  }

  dismiss() {
    // 알림 제거 (애니메이션과 함께)
    this.containerTarget.classList.add("fade-out");
    setTimeout(() => {
      this.containerTarget.remove();
    }, 300);
  }
}
