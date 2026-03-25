import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "icon"];
  static values = { revealed: { type: Boolean, default: false } };

  get realValue() {
    if (this._realValue === undefined) {
      this._realValue = this.element.dataset.sensitiveFieldRealValue || "";
    }
    return this._realValue;
  }

  toggle() {
    this.revealedValue = !this.revealedValue;
  }

  revealedValueChanged() {
    if (this.revealedValue) {
      this.displayTarget.textContent = this.realValue;
      this.iconTarget.classList.replace("fa-eye", "fa-eye-slash");
    } else {
      this.displayTarget.textContent = "\u2022".repeat(this.realValue.length || 8);
      this.iconTarget.classList.replace("fa-eye-slash", "fa-eye");
    }
  }
}
