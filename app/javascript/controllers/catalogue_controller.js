import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["dataAdministrator", "dataAdministrators", "addAdmin", "destroy"];

  addAdmin(event) {
    event.preventDefault();
    event.target.insertAdjacentHTML(
      "beforebegin",
      event.target.dataset.fields.replace(/new_field/g, this.dataAdministratorTargets.length),
    );
  }

  removeAdmin(event) {
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").classList.add("d-none");
  }
}
