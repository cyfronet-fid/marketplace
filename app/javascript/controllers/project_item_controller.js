import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hasVoucher", "iHaveVoucher", "iDontHaveVoucher"];

  voucherChanged(event) {
    if (event.currentTarget.value === "false") {
      this.hasVoucherTarget.classList.remove("hidden-fields");
      this.iHaveVoucherTarget.classList.add("active");
      this.iDontHaveVoucherTarget.classList.remove("active");
    } else {
      this.hasVoucherTarget.classList.add("hidden-fields");
      this.iHaveVoucherTarget.classList.remove("active");
      this.iDontHaveVoucherTarget.classList.add("active");
    }
  }
}
