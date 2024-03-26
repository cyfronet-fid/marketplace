import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [ "alternativeTitle", "addField", "form", "destroy" ]
  connect() {
    console.log(this.formTarget.dataset.disabled)
    console.log("Raid project controller connected");
  }
  addField(event) {
    event.preventDefault();
    this.alternativeTitles = this.alternativeTitleTargets;
    const quantity = this[event.target.dataset.value].length;
    event.target.insertAdjacentHTML("beforebegin", event.target.dataset.fields.replace(/new_field/g, quantity));
  }

  removeField(event) {
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").classList.add("d-none");
  }
}
