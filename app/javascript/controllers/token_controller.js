import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "content"];

  connect() {
    this.hide();
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();
    if (this.hasContentTarget && this.contentTarget.classList.contains("show-token")) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this.contentTarget.classList.add("show-token");
    this.contentTarget.innerHTML = this.contentTarget.dataset.token;
    this.buttonTarget.innerHTML = "Hide token";
  }

  hide() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("show-token");
      this.contentTarget.innerHTML = "********************";
      this.buttonTarget.innerHTML = "Show token";
    }
  }
}
