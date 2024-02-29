import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["showMore"];

  showMore(event) {
    const element = event.target;
    event.preventDefault();
    this.showMoreTarget.parentElement.innerHTML = element.dataset.text;
  }
}
