import { Controller } from "@hotwired/stimulus";
import initChoices from "../app/choices";

export default class extends Controller {
  static targets = [
    "singleUser",
    "customer",
    "research",
    "originCountry",
    "partnershipCountries",
    "customerHint",
    "project",
    "privateCompany",
    "input",
  ];

  connect() {
    initChoices();
  }

  initialize() {
    this.CUSTOMER_TYPOLOGIES = {
      single_user: "single_user",
      research: "research",
      private_company: "private_company",
      project: "project",
    };
    this.showSelectedSection();
  }

  showSelectedSection() {
    const customer = this.customerTarget.value;

    this._hideCustomerTypologieFields();
    if (customer === this.CUSTOMER_TYPOLOGIES.single_user) {
      this._showFields(this.singleUserTargets);
      this._createHint(this.originCountryTarget.parentElement, "In which country is your institution located?");
    }
    if (customer === this.CUSTOMER_TYPOLOGIES.research) {
      this._showFields(this.researchTargets);
      this._createHint(
        this.partnershipCountriesTarget,
        "Which countries are involved in this community? Please select those you are aware of",
      );
    }
    if (customer === this.CUSTOMER_TYPOLOGIES.project) {
      this._showFields(this.projectTargets);
      this._createHint(
        this.partnershipCountriesTarget,
        "Which countries are involved in these projects? Please select those you are aware of",
      );
    }
    if (customer === this.CUSTOMER_TYPOLOGIES.private_company) {
      this._showFields(this.privateCompanyTargets);
      this._createHint(this.originCountryTarget.parentElement, "Where is it located?");
    }
  }

  _hideCustomerTypologieFields() {
    this.inputTargets.forEach((el, i) => {
      if (!el.classList.contains("hidden-fields")) {
        el.classList.add("hidden-fields");
      }
    });
  }

  _createHint(element, hint) {
    if (element.querySelector("small")) {
      element.removeChild(element.querySelector("small"));
    }
    const small = document.createElement("small");
    small.innerText = hint;
    small.classList.add("form-text", "text-muted");
    element.appendChild(small);
  }

  _showFields(fields) {
    fields.forEach((el, i) => {
      el.classList.remove("hidden-fields");
    });
  }

  filterFields(event) {
    this.inputTargets.forEach((el) => {
      if (el.classList.contains("hidden-fields")) {
        var hidden_element = el.getElementsByClassName("form-control")[0];
        hidden_element.value = "";
        if (hidden_element.classList.contains("choices__input")) {
          var empty_option = document.createElement("option");
          empty_option.selected = true;
          hidden_element.add(empty_option);
        }
      }
    });
  }
}
