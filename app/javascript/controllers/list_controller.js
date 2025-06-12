import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="list"
export default class extends Controller {
  static targets = ["name", "checkbox", "selectedMenu", "itemMenu", "checkAll"];
  connect() {}

  toggleAll(event) {
    const target = event.currentTarget;
    this.checkboxTargets.forEach((el) => (el.checked = target.checked));
    this.toggleActions();
  }

  toggleCurrent(event) {
    event.preventDefault();
    const target = document.getElementById(event.currentTarget.dataset.value);
    target.checked = !target.checked;
    this.toggleActions();
  }

  toggleActions(event) {
    if (this.checkboxTargets.filter((el) => el.checked).length < 2) {
      this.selectedMenuTarget.classList.add("d-none");
      this.itemMenuTargets.forEach((el) => el.classList.remove("d-none"));
    } else {
      this.selectedMenuTarget.classList.remove("d-none");
      this.itemMenuTargets.forEach((el) => el.classList.add("d-none"));
    }
  }

  checkIndetermination(event) {
    const state = event.currentTarget.checked;
    if (this.checkboxTargets.some((e) => e.checked !== state)) {
      this.checkAllTarget.checked = false;
      this.checkAllTarget.indeterminate = true;
      this.checkAllTarget.classList.add("indeterminate");
      return;
    }
    this.checkAllTarget.indeterminate = false;
    this.checkAllTarget.classList.remove("indeterminate");
    this.checkAllTarget.checked = state;
  }

  reset(event) {
    this.checkAllTarget.checked = false;
    this.checkAllTarget.indeterminate = false;
  }
}
