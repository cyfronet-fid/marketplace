import { Controller } from "@hotwired/stimulus";
import initChoices from "../app/choices";

export default class extends Controller {
  static targets = [
    "addField",
    "mainDescription",
    "descriptionLanguage",
    "descriptionText",
    "alternativeDescription",
    "alternativeTitle",
    "contributor",
    "destroy",
    "raidOrganisation",
    "results",
    "rorInput",
    "rorValue",
    "selectedOption",
    "accessType",
    "embargoExpiry",
    "embargoExpiryInput",
    "statementText",
    "statementLanguage"

  ];
  static values = {
    url: String,
    value: String,
  };
  connect() {
    // console.log("Raid project controller connected");
    initChoices();
  }

  autocomplete(event) {
    this.currentElementIndex = event.target.id.split("_")[5];
    
    const query = this.rorInputTargets[this.currentElementIndex].value.trim();
    if (query.length > 2) {
      const params = new URLSearchParams(window.location.search.slice(1));
      params.append("q", query);
      const url = new URL(this.urlValue);
      url.search = params.toString();
      this.element.dispatchEvent(new CustomEvent("loadstart"));
      fetch(url.toString(), { headers: { "X-Requested-With": "XMLHttpRequest" } })
        .then((response) => response.text())
        .then((body) => this.success(body))
        .catch((response) => this.error(response));
    }
  }

  success(body) {
    const currentResult = this.resultsTargets[this.currentElementIndex];
    currentResult.innerHTML = body;

    const hasResults = !!currentResult.querySelector('[role="option"]');
    currentResult.hidden = !hasResults;
    this.element.dispatchEvent(new CustomEvent("load"));
    this.element.dispatchEvent(new CustomEvent("loadend"));
  }

  error(response) {
    this.element.dispatchEvent(new CustomEvent("error"));
    this.element.dispatchEvent(new CustomEvent("loadend"));
  }

  pickOption(event) {
    let chosenValue = event.target.getAttribute("data-raid-project-value");
    let chosenName = event.target.getAttribute("data-raid-project-display");
    this.rorInputTargets[this.currentElementIndex].value = chosenName;
    this.rorValueTargets[this.currentElementIndex].value = chosenValue;
    this.resultsTargets[this.currentElementIndex].innerHTML = "";
  }

  addField(event) {
    event.preventDefault();
    this.alternativeTitles = this.alternativeTitleTargets;
    this.alternativeDescriptions = this.alternativeDescriptionTargets;
    this.contributors = this.contributorTargets;
    this.raidOrganisations = this.raidOrganisationTargets;
    const quantity = this[event.target.dataset.value].length;
    event.target.insertAdjacentHTML("beforebegin", event.target.dataset.fields.replace(/new_field/g, quantity));
    initChoices();
  }

  removeField(event) {
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").remove();
  }

  addDescription(event) {
    event.preventDefault();
    this.mainDescriptionTarget.classList.add('d-none') ;
    document.getElementById("main-description").classList.remove('d-none') ;
  }

  removeDescription(event) {
    event.preventDefault();
    this.descriptionTextTarget.value = '';
    this.descriptionLanguageTarget.value = '';
    document.getElementById("main-description").classList.add('d-none');
    this.mainDescriptionTarget.classList.remove('d-none') ;
  }

  setEmbargoed(event) {
    const accessType = this.accessTypeTarget.value;
   
    if (accessType == "open") {
      this.embargoExpiryTarget.classList.add('d-none');
      this.embargoExpiryInputTarget.value = ""
    } else {
      this.embargoExpiryTarget.classList.remove('d-none');
      
    }
  } 
}
