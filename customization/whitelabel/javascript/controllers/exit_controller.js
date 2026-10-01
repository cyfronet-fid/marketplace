import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ["display", "modal", "modalContent", "modalNameInput", "formNameInput"];

  connect() {
    document.addEventListener("change", (event) => this.addAlert(event));
  }

  showModal(e) {
    this.modalTarget.classList.remove("d-none");
    this.modalNameInputTarget.value = this.formNameInputTarget.value;
  }

  hideModal(e) {
    this.modalTarget.classList.add("d-none");
  }

  addAlert(event) {
    this.displayTarget.dataset.turboConfirm = "Exit provider editor";
    this.displayTarget.dataset.confirmCancel = "Go back to edition";
    this.displayTarget.dataset.confirmButton = "Exit without saving";
  }

  recirectToProvider(event) {
    Turbo.visit(`/backoffice/providers/${event.target.dataset.providerId}`);
  }

  redirectToExtendedForm(event) {
    Turbo.visit(`/backoffice/providers/${event.target.dataset.providerId}/edit?step=legal_status`);
  }

  // hide modal when clicking ESC
  // action: "keyup@window->turbo-modal#closeWithKeyboard"
  closeWithKeyboard(e) {
    if (e.code == "Escape") {
      this.hideModal();
    }
  }

  // hide modal when clicking outside of modal
  // action: "click@window->turbo-modal#closeBackground"
  closeBackground(e) {
    if (
      this.hasDisplayTarget &&
      e &&
      (this.displayTarget.contains(e.target) || this.modalContentTarget.contains(e.target))
    ) {
      return;
    }
    this.hideModal(e);
  }
}
