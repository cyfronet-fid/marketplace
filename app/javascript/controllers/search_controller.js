import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["categorySelect", "form", "selected", "type"];

  connect() {
    this.SERVICES_URL = this.data.get("servicesPath");
    this.CATEGORIES_URL = this.data.get("categoriesPath");

    this.categorySelectTarget.value = "";
    let match = window.location.pathname.match(new RegExp(`^.*${this.CATEGORIES_URL}/([^/]+$)`));
    if (match !== null) this.categorySelectTarget.value = match[1];

    this.refresh();
  }

  refresh() {
    let actionURL = this.SERVICES_URL;

    if (this.categorySelectTarget.value !== "") actionURL = `${this.CATEGORIES_URL}/${this.categorySelectTarget.value}`;

    this.selectedTarget.innerHTML = this.getSelectedText();
    this.formTarget.setAttribute("action", actionURL);
  }

  getSelectedText() {
    return this.categorySelectTarget.options[this.categorySelectTarget.selectedIndex].text;
  }
}
