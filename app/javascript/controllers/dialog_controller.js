import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.previouslyFocusedElement = document.activeElement;
    this.bodyWasLocked = document.body.classList.contains("overflow-hidden");
    document.body.classList.add("overflow-hidden");
    if (!this.element.open) {
      this.element.showModal();
    }
  }

  disconnect() {
    this.unlockBody();
  }

  close() {
    this.element.close();
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) {
      this.close();
    }
  }

  handleClose() {
    this.unlockBody();
    this.previouslyFocusedElement?.focus();
    this.element.remove();
  }

  unlockBody() {
    if (!this.bodyWasLocked) {
      document.body.classList.remove("overflow-hidden");
    }
  }
}
