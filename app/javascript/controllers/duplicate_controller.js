import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "form", "modalNameInput"];

  connect() {
    console.log("duplicate modal controller connected");
  }

  showModal(event) {
    event.preventDefault();
    const form = this.formTarget;
    form.action = event.target.dataset.duplicateUrl;
    this.modalTarget.classList.remove("d-none");
    this.modalNameInputTarget.value = event.target.dataset.offerName;
  }
}
