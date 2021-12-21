import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["hideableParameter"];

  initialize() {}

  toggleParameters(event) {
    event.preventDefault();
    const element = event.target;
    const hidden = this.hideableParameterTargets;
    if (element.dataset.state == "hidden") {
      element.innerText = "Show less";
      element.dataset.state = "visible";
      for (const el of hidden) {
        el.classList.remove("d-none");
      }
    } else {
      element.innerText = "Show more";
      element.dataset.state = "hidden";
      for (const el of hidden) {
        el.classList.add("d-none");
      }
    }
  }
}
