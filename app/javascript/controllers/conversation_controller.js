import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["separator"];

  hide_separator() {
    if (this.hasSeparatorTarget) {
      this.separatorTarget.style.display = "none";
    }
  }
}
