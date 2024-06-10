import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    console.log(this.modalTarget.dataset);
    if (!this.modalTarget.dataset.hasOwnProperty("overflowEnabled")) {
      document.body.classList.add("overflow-hidden");
    }
  }

  hideModal() {
    this.element.parentElement.removeAttribute("src");
    // Remove src reference from parent frame element
    // Without this, turbo won't re-open the modal on subsequent click
    this.modalTarget.remove();
    document.body.classList.remove("overflow-hidden");
  }

  // hide modal on successful form submission
  // action: "turbo:submit-end->turbo-modal#submitEnd"
  submitEnd(e) {
    if (e.detail.success) {
      this.hideModal();
    }
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
    if (e && this.modalTarget.contains(e.target)) {
      return;
    }
    this.hideModal();
  }
}
