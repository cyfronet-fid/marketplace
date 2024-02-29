import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["price", "quantity"];

  connect() {
    this.calculate();
  }

  calculate(event) {
    this.priceTarget.innerHTML = this.price;
  }

  get price() {
    let quantity = Number(this.quantityTarget.value);
    if (quantity > 0) {
      return Number(this.data.get("start-price")) + (quantity - 1) * Number(this.data.get("step-price"));
    } else {
      return 0;
    }
  }
}
