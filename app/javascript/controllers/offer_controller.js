import { Controller } from "@hotwired/stimulus";
import Rails from "@rails/ujs";
import initChoices from "../app/choices";
import Choices from "choices.js";

const offerFormSections = ["offer-type", "order-parameters", "offer-parameters", "description", "summary"];

export default class extends Controller {
  static targets = [
    "attributes",
    "attributeType",
    "button",
    "category",
    "external",
    "form",
    "nextButton",
    "parameters",
    "prevButton",
    "radioButton",
    "section",
    "sectionButton",
    "submitRow",
    "subtype",
    "type",
  ];

  initialize() {
    this.indexCounter = 0;
    if (this.attributesTarget.firstElementChild) {
      this.attributesTarget.classList.add("active");
    }
    const choicesConfig = {
      removeItems: true,
      allowHTML: true,
      duplicateItemsAllowed: false,
      placeholder: true,
      placeholderValue: "+ start typing to add",
    };
    this.setRadioButtonsStates();
    if (this.hasCategoryTarget) {
      this.categoryChoices = new Choices(this.categoryTarget, {
        removeItems: true,
        allowHTML: true,
        duplicateItemsAllowed: false,
        shouldSort: false,
      });
    }
    if (this.hasTypeTarget) {
      this.typeChoices = new Choices(this.typeTarget, choicesConfig);
    }
    if (this.hasSubtypeTarget) {
      this.subtypeChoices = new Choices(this.subtypeTarget, choicesConfig);
    }
  }

  add(event) {
    const template = this.buttonTarget.dataset.template.replace(/js_template_id/g, this.generateId());
    const newElement = document.createRange().createContextualFragment(template).firstChild;

    this.attributesTarget.appendChild(newElement);
    initChoices(newElement);

    this.buttonTarget.disabled = true;
    this.fromArrayRemoveSelect();
    this.attributesTarget.classList.add("active");
    this.buttonTarget.classList.remove("active");
  }

  generateAttribute(attr) {
    const currentId = this.generateId();
    const template = this.attributeTypeTargets
      .find((t) => t.id === attr.type)
      .dataset.template.replace(/js_template_id/g, currentId);
    const newElement = document.createRange().createContextualFragment(template).firstChild;

    this.attributesTarget.appendChild(newElement);
    Object.keys(attr).forEach((key, index) => {
      const param = document.getElementById(`offer_parameters_attributes_${currentId}_${key}`);
      if (param) {
        param.value = attr[key];
      }
    });
    initChoices(newElement);
  }

  generateId() {
    return (new Date().getTime() % 10000) + this.indexCounter++;
  }

  remove(event) {
    event.target.closest(".parameter-form").remove();
    if (!this.attributesTarget.firstElementChild) {
      this.attributesTarget.classList.remove("active");
    }
  }

  selectParameterType(event) {
    const template = event.target.dataset.template;
    this.buttonTarget.disabled = false;
    this.setSelect(event);
    this.buttonTarget.dataset.template = template;
    this.buttonTarget.classList.add("active");
  }

  setSelect(event) {
    this.fromArrayRemoveSelect();
    event.target.classList.add("selected");
  }

  fromArrayRemoveSelect() {
    this.attributeTypeTargets.forEach(this.removeSelect);
  }

  removeSelect(elem, index) {
    elem.classList.remove("selected");
  }

  up(event) {
    const current = event.target.closest(".parameter-form");
    const previous = current.previousElementSibling;

    if (previous != undefined) {
      current.parentNode.insertBefore(current, previous);
    }
  }

  down(event) {
    const current = event.target.closest(".parameter-form");
    const next = current.nextElementSibling;

    if (next != undefined) {
      current.parentNode.insertBefore(next, current);
    }
  }

  showSection(event) {
    const section = event.currentTarget.dataset.section;

    if (section === "summary") {
      this._submitSummary();
      return;
    }

    this._toggleSection(section);
  }

  nextSection() {
    const currentSection = this.sectionButtonTargets.findLast((e) => e.classList.contains("active-button")).dataset
      .section;

    const nextSection = offerFormSections[offerFormSections.indexOf(currentSection) + 1];

    if (nextSection === "summary") {
      this._submitSummary();
      return;
    }

    this._toggleSection(nextSection);
  }

  prevSection() {
    const currentSection = this.sectionButtonTargets.findLast((e) => e.classList.contains("active-button")).dataset
      .section;

    const prevSection = offerFormSections[offerFormSections.indexOf(currentSection) - 1];
    this._toggleSection(prevSection);
  }

  _submitSummary() {
    const formData = new FormData(this.formTarget);
    const serviceId = this.formTarget.dataset.serviceId;
    const offerId = this.formTarget.dataset.offerId;
    const url = `/backoffice/services/${serviceId}/offers/${offerId}/summary`;

    fetch(url, {
      method: this.formTarget.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      credentials: "include",
    })
      .then((response) => {
        if (response.ok) {
          return response.text();
        } else {
          throw response;
        }
      })
      .then((html) => {
        const summarySection = this.element.querySelector('[data-offer-target="section"][data-section="summary"]');
        summarySection.innerHTML = html;
        this._toggleSection("summary");
      })
      .catch((error) => {
        error.json().then((err) => {
          console.error("Error submitting form:", err.errors);
        });
      });
  }

  setRadioButtonsStates() {
    const targets = this.radioButtonTargets;
    targets.forEach((element) => {
      if (element.checked) {
        element.parentNode.classList.add("active");
      }
    });
  }

  toggleRadioButton(event) {
    const currentTarget = event.target;
    const scoped = this.radioButtonTargets.filter((e) => e.name === currentTarget.name);

    scoped.forEach((element) => {
      element.parentNode.classList.remove("active");
    });
    currentTarget.parentNode.classList.add("active");
  }

  async updateChildren(event) {}

  async updateParameters(event) {
    const value = event.target.value;
    const serviceId = this.formTarget.dataset.serviceId;
    const offerId = this.formTarget.dataset.offerId;
    const response = await this.getSubtypes(value, serviceId, offerId);
    const json = await response.json();

    if (json.hasOwnProperty("types")) {
      this.typeChoices.clearChoices();
      this.typeChoices.removeActiveItems();
      await this.typeChoices.setChoices(json.types);
      const wrapper = this.typeTarget.closest(".form-group.select");
      json.types.length == 0 ? wrapper.classList.add("d-none") : wrapper.classList.remove("d-none");
    }
    if (json.hasOwnProperty("subtypes")) {
      this.subtypeChoices.clearChoices();
      this.subtypeChoices.removeActiveItems();
      await this.subtypeChoices.setChoices(json.subtypes);
      const sub_wrapper = this.subtypeTarget.closest(".form-group.select");
      json.subtypes.length == 0 ? sub_wrapper.classList.add("d-none") : sub_wrapper.classList.remove("d-none");
    }
    if (json.hasOwnProperty("parameters")) {
      await this.setParameters(json.parameters);
    }
  }

  setParameters(json) {
    this.attributesTarget.innerHTML = "";
    Array.from(json).forEach((attr) => this.generateAttribute(attr));
  }

  async getSubtypes(value, serviceId, offerId) {
    const data = `service_category=${value}&offer_id=${offerId}`;
    const rawResponse = await fetch(`/backoffice/services/${serviceId}/offers/fetch_subtypes`, {
      method: "POST",
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": Rails.csrfToken(),
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: data,
    });
    return rawResponse;
  }

  _toggleSection(section) {
    const sectionIndex = offerFormSections.indexOf(section);

    this.sectionButtonTargets.forEach((element) => {
      const elementIndex = offerFormSections.indexOf(element.dataset.section);
      if (elementIndex <= sectionIndex) {
        element.classList.add("active-button");
      } else {
        element.classList.remove("active-button");
      }
    });

    this.sectionTargets.forEach((element) => {
      if (element.dataset.section === section) {
        element.classList.remove("d-none");
      } else {
        element.classList.add("d-none");
      }
    });

    this._displaySubmitRow();
    this._displayPrevButton();
    this._displayNextButton();

    if (section === "offer-type") {
      this._hidePrevButton();
    }

    if (section === "summary") {
      this._hideNextButton();
    }

    if (section !== "summary") {
      this._hideSubmitRow();
    }
  }

  _displaySubmitRow() {
    this.submitRowTarget.classList.remove("d-none");
  }

  _hideSubmitRow() {
    this.submitRowTarget.classList.add("d-none");
  }

  _displayNextButton() {
    this.nextButtonTarget.classList.remove("d-none");
  }

  _hideNextButton() {
    this.nextButtonTarget.classList.add("d-none");
  }

  _displayPrevButton() {
    this.prevButtonTarget.classList.remove("d-none");
  }

  _hidePrevButton() {
    this.prevButtonTarget.classList.add("d-none");
  }
}
