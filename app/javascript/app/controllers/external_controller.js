import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["query", "clear", "search"];

  connect() {}

  clear() {
    this.queryTarget.value = "";
    this.clearTarget.classList.add("d-none");
  }

  toggleClear() {
    if (this.queryTarget.value !== "") {
      this.clearTarget.classList.remove("d-none");
    } else {
      this.clearTarget.classList.add("d-none");
    }
  }

  search() {
    window.location = `https://search.marketplace.eosc-portal.eu/search/all?q=${this.queryTarget.value || "*"}`;
  }
}
