import { Controller } from "@hotwired/stimulus";
import initChoices from "../app/choices";

export default class extends Controller {
  static targets = [
    "array",
    "form",
    "input",
    "publicContact",
    "mainContact",
    "destroy",
    "multimedia",
    "useCase",
    "serviceType",
    "datasourceFields",
    "alternativeIdentifier",
    "researchProductLicense",
    "researchProductMetadataLicense",
    "persistentIdentitySystem",
    "addField",
    "multimedia",
    "changelog",
    "grantProjectNames",
    "certifications",
    "standards",
    "openSourceTechnologies",
    "useCasesUrl",
    "relatedPlatforms",
    "affiliations",
    "national_roadmaps",
    "fixme",
    "tag_list",
    "mcFirstName",
    "mcLastName",
    "mcEmail",
    "mcPhone",
    "mcPosition",
    "mcCode",
    "pcFirstName",
    "pcLastName",
    "pcEmail",
    "pcPhone",
    "pcPosition",
    "pcCode",
    "tab",
  ];

  initialize() {
    this.addListenersForCollapse();
    this.disableFormButtons();
    this.handleRelatedFields();
    initChoices();
  }

  onScroll(event) {
    event.preventDefault();
    const titlePosition = document.getElementById("title").offsetTop;
    const footerPosition = document.getElementsByTagName("footer")[0].offsetTop;
    if (window.scrollY > titlePosition && window.scrollY < footerPosition - 750) {
      this.fixmeTarget.style.position = "fixed";
      this.fixmeTarget.style.top = "10px";
    } else if (window.scrollY > footerPosition - 1000) {
      this.fixmeTarget.style.position = "absolute";
      this.fixmeTarget.style.top = footerPosition - 1000 + "px";
    } else {
      this.fixmeTarget.style.position = "static";
    }
  }

  toggleTab(event) {
    event.preventDefault();
    this.tabTargets.forEach((el) => {
      el.classList.remove("active");
    });
    const toDisplay = document.getElementById(event.target.dataset.target);
    toDisplay.classList.add("active");
  }

  duplicateContact(event) {
    event.preventDefault();
    this.pcFirstNameTarget.value = this.mcFirstNameTarget.value;
    this.pcLastNameTarget.value = this.mcLastNameTarget.value;
    this.pcCodeTarget.value = this.mcCodeTarget.value;
    this.pcPhoneTarget.value = this.mcPhoneTarget.value;
    this.pcEmailTarget.value = this.mcEmailTarget.value;
    this.pcPositionTarget.value = this.mcPositionTarget.value;
  }

  updateForm() {
    switch (this.serviceTypeTarget.value) {
      case "Service": {
        this.datasourceFieldsTargets.forEach((el) => {
          el.classList.add("d-none");
        });
        break;
      }
      case "Datasource": {
        this.datasourceFieldsTargets.forEach((el) => {
          el.classList.remove("d-none");
        });
        break;
      }
    }
  }

  disableFormButtons() {
    if (this.formTarget.dataset.disabled === "true") {
      const elements = document.getElementsByClassName("disablable");
      for (let i = 0; i < elements.length; i++) {
        elements[i].classList.add("disabled");
      }
    }
  }

  addListenersForCollapse() {
    // TODO: change this function if bootstrap events will be enabled without jQuery
    $(".accordion")
      .find(".collapse")
      .on("shown.bs.collapse", function () {
        this.previousElementSibling.scrollIntoView({ behavior: "smooth" });
      });
  }

  addNewArrayField(event) {
    event.preventDefault();
    const lastArrayField = document.createElement("textarea");
    const parentName = event.target.dataset.wrapper;
    const parent = document.getElementsByClassName(parentName)[0];

    lastArrayField.name = event.target.dataset.name;
    lastArrayField.id = parentName + "_" + parent.getElementsByTagName("textarea").length;
    lastArrayField.classList = event.target.dataset.class;

    const removeLink = document.createElement("a");

    const linkText = document.createTextNode("Remove");

    removeLink.id = "remove_" + lastArrayField.id;
    removeLink.dataset.target = event.target;
    removeLink.dataset.action = "click->form#removeArrayField";
    removeLink.dataset.value = lastArrayField.id;
    removeLink.appendChild(linkText);
    removeLink.classList.add("btn-sm", "btn-danger", "remove", "float-right");

    parent.appendChild(lastArrayField);
    parent.appendChild(removeLink);
  }

  removeArrayField(event) {
    event.preventDefault();
    document.getElementById(event.target.dataset.value).remove();
    event.target.remove();
  }

  addField(event) {
    event.preventDefault();
    this.alternativeIdentifier = this.alternativeIdentifierTargets;
    this.useCases = this.useCaseTargets;
    this.multimedia = this.multimediaTargets;
    this.publicContacts = this.publicContactTargets;
    this.persistentIdentitySystems = this.persistentIdentitySystemTargets;
    this.researchProductLicense = this.researchProductLicenseTargets;
    this.researchProductMetadataLicense = this.researchProductMetadataLicenseTargets;
    const quantity = this[event.target.dataset.value].length;
    event.target.insertAdjacentHTML("beforebegin", event.target.dataset.fields.replace(/new_field/g, quantity));
    initChoices();
  }

  removeField(event) {
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").classList.add("d-none");
  }

  handleRelatedFields() {
    Array.from(this.formTarget.querySelectorAll("[data-child-field]")).forEach((parent) => {
      const childId = parent.getAttribute("data-child-field");
      const child = this.formTarget.querySelector("[class*=" + childId + "]");
      this._hasInputValue(parent) ? child.classList.remove("d-none") : child.classList.add("d-none");
    });
  }

  refreshRelatedFields(event) {
    const childId = event.target.getAttribute("data-child-field");
    if (!childId) {
      return;
    }

    const child = this.formTarget.querySelector("[class*=" + childId + "]");
    this._hasInputValue(event.target) ? child.classList.remove("d-none") : child.classList.add("d-none");
  }

  goToSummary(event) {
    document.getElementById("summary-step-link").click();
  }

  _hasInputValue(input) {
    const tag = input.tagName;
    switch (tag.toLowerCase()) {
      case "input":
        return input.type === "checkbox" ? input.checked : !!input.value && input.value !== "";
      case "textarea":
        return input.val();
      default:
        return input.textContent;
    }
  }
}
