import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "modalNameInput", "formNameInput"];

  connect() {
    console.log("exit modal controller connected");
  }

  showModal(event) {
    event.preventDefault();
    this.modalTarget.classList.remove("d-none");
    this.modalNameInputTarget.value = this.formNameInputTarget.value;
  }
}
