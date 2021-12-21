import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["button", "content"];

  connect() {
    this.hide();
  }

  toggle() {
    if (this.contentTarget.classList.contains("show-token")) {
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
    this.contentTarget.classList.remove("show-token");
    this.contentTarget.innerHTML = "********************";
    this.buttonTarget.innerHTML = "Show token";
  }
}
