import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["share", "email", "form"];

  connect() {}

  initialize() {}

  share(event) {
    if (this.emailTarget) {
      event.target.checked ? this.emailTarget.classList.add("show") : this.emailTarget.classList.remove("show");
    }
  }

  onPostSuccess(event) {
    $(document.getElementById("tour-feedback-modal")).modal("hide");
  }

  onPostError(event) {
    let [data, status, xhr] = event.detail;
    this.formTarget.parentElement.innerHTML = xhr.response;
  }
}
