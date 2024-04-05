import { Controller } from "stimulus";
import initChoices from "../choices";

export default class extends Controller {
  static targets = [
    "addField", 
    "alternativeDescription", 
    "alternativeTitle",
    "contributor",
    "raid_organisation",
    "destroy",
    "form"
  ];
  connect() {
    console.log("Raid project controller connected");
  }
  addField(event) {
    console.log('adding')
    event.preventDefault();
    this.alternativeTitles = this.alternativeTitleTargets;
    this.alternativeDescriptions = this.alternativeDescriptionTargets;
    this.contributors = this.contributorTargets;
    this.raid_organisations = this.raidOrganisationTargets;
    const quantity = this[event.target.dataset.value].length;
    event.target.insertAdjacentHTML("beforebegin", event.target.dataset.fields.replace(/new_field/g, quantity));
    initChoices();
  }

  removeField(event) {
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").classList.add("d-none");
  }
}
