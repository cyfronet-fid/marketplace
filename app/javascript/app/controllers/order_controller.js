import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["form", "select"];

  connect() {}

  initialize() {}

  reload(event) {
    let form = this.formTarget;
    form.submit();
    document.getElementsByClassName("spinner-background")[0].style.display = "flex";
  }
}
