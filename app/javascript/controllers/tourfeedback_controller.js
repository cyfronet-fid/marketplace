import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["point", "line", "input"];

  connect() {
    const rating = parseInt(this.inputTarget.getAttribute("value"));
    !isNaN(rating) && this._setRating(rating);
  }

  initialize() {}

  rate(event) {
    this.element.classList.remove("is-invalid");
    const rating = this.pointTargets.indexOf(event.target);
    this.inputTarget.setAttribute("value", rating);
    this._setRating(rating);
  }

  _setRating(rating) {
    this.pointTargets.forEach((point, i) => {
      if (i <= rating) {
        i > 0 && this.lineTargets[i - 1].classList.add("active");
        point.classList.add("active");
      } else {
        i > 0 && this.lineTargets[i - 1].classList.remove("active");
        point.classList.remove("active");
      }
    });
  }
}
