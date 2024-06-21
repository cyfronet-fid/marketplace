import { Controller } from "@hotwired/stimulus";
import initChoices from "../app/choices";

export default class extends Controller {
  static targets = [
    "addField",
    "alternativeDescription",
    "alternativeTitle",
    "contributor",
    "destroy",
    "form",
    "raidOrganisation",
    "results",
    "rorInput",
    "rorValue",
    "selectedOption",
    "section",
    "sectionButton",
  ];
  static values = {
    url: String,
    value: String,
  };
  connect() {
    console.log("Raid project controller connected");
    initChoices();
  }

  autocomplete(event) {
    this.currentElementIndex = event.target.id.split("_")[5];
    this.accessType = this.accessTypeTarget;
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

  steps() {
    return ["step1", "step2", "step3", "step4", "step5"]
  }

  currentStep(){
    console.log(this.sectionTarget.dataset.section);
    return this.steps().indexOf(this.sectionTarget.dataset.section);
  }

  setNextStepActive() {
    let currentStepIndex = this.currentStep();
    if (currentStepIndex < 4) 
      {
        let nextStepButton = this.sectionButtonTargets[currentStepIndex + 1];
        nextStepButton.classList.add("active-button");
      }
  }

  setCurrentStepInactive() {
    let currentStepIndex = this.currentStep();
    if (currentStepIndex > 0) {
      let currentStepButton = this.sectionButtonTargets[currentStepIndex];
      currentStepButton.classList.remove("active-button");
    }
  }

  setActiveSteps(event) {
    let chosenStep = event.target.getAttribute("data-raid-project-step");
    let chosenStepIndex = this.steps().indexOf(chosenStep);
    this.steps = this.sectionButtonTargets;
    let activeSteps = this.steps.slice(0, chosenStepIndex + 1);
    let inactiveSteps = this.steps.slice(chosenStepIndex + 1);
    activeSteps.forEach(step => {
      step.classList.add("active-button");
    });
    inactiveSteps.forEach(step => {
      step.classList.remove("active-button");
    });
    
  }

}
