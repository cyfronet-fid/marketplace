import { Controller } from "@hotwired/stimulus";
import initFlash from "../app/flash";

export default class extends Controller {
  static targets = ["modal"];

  hideModal() {
    this.element.parentElement.removeAttribute("src");
    // Remove src reference from parent frame element
    // Without this, turbo won't re-open the modal on subsequent click
    this.modalTarget.remove();
    initFlash();
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
