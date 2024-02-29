import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["link", "tab", "content", "details"];

  initialize() {
    this.linkTargets.forEach((link) => {
      link.href = "javascript:;";
    });
  }

  toggle(event) {
    const tab = document.getElementById(event.currentTarget.dataset.value);

    this.contentTargets.forEach((el) => {
      el.classList.add("d-none");
    });
    this.tabTargets.forEach((tab) => {
      tab.classList.remove("active");
    });
    if (event.currentTarget.classList.contains("more-details")) {
      this.detailsTarget.classList.add("active");
    } else {
      event.currentTarget.classList.add("active");
    }
    tab.classList.remove("d-none");
  }
}
