import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "select", "checkbox"];

  connect() {}

  initialize() {}

  reload(event) {
    let form = this.formTarget;
    form.submit();
    document.getElementsByClassName("spinner-background")[0].style.display = "flex";
  }

  uncheck(event) {
    let target = event.target;
    this.checkboxTargets.forEach((el) => {
      el.checked = false;
    });
    target.closest("label").firstElementChild.checked = true;
  }
}
