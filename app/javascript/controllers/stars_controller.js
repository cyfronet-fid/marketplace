import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["ratingStars"];

  connect() {}

  initialize() {}

  fill(event) {
    name = this.ratingStarsTarget.attributes["data-rating-stars"].value;
    let star_value = event.target.getAttribute("value") || this._getParentValue(event.target, "value");

    let value = (document.getElementById(name).value = star_value);
    let stars = this.ratingStarsTarget.children;

    for (let el of stars) {
      let star = el.firstElementChild;
      star.getAttribute("value") <= value
        ? star.setAttribute("data-prefix", "fas")
        : star.setAttribute("data-prefix", "far");
    }
  }

  _getParentValue(element, attribute) {
    return element.parentElement.attributes[attribute] ? element.parentElement.attributes[attribute].value : null;
  }
}
