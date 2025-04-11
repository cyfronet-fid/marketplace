import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source"];

  initialize() {}

  connect() {
    if (document.queryCommandSupported("copy")) {
      this.element.classList.add("clipboard--supported");
    }
  }

  copy(e) {
    e.preventDefault();
    this.sourceTarget.select();
    document.execCommand("copy");
  }
}
