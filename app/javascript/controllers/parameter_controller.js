import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hideableParameter", "switch"];

  initialize() {}

  toggleParameters(event) {
    event.preventDefault();
    const element = this.switchTarget;
    const hidden = this.hideableParameterTargets;
    const state = element.dataset.state;
    element.firstChild.innerText = state === "hidden" ? "Show less" : "Show more";
    element.classList.toggle("collapsed");
    this.toggleState(element);
    for (const el of hidden) {
      this.toggleState(el);
      el.classList.toggle("d-none");
    }
  }

  toggleState(el) {
    el.dataset.state = el.dataset.state === "hidden" ? "visible" : "hidden";
  }
}
