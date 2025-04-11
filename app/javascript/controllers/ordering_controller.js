import { Controller } from "@hotwired/stimulus";
import initChoices from "../app/choices";

export default class extends Controller {
  static targets = [
    "counter",
    "orderType",
    "internal",
    "internalDescription",
    "internalWrapper",
    "training",
    "trainingWrapper",
    "primaryOms",
    "primaryOmsWrapper",
    "orderUrlWrapper",
    "omsParamsContainer",
    "capabilities",
    "suggestion",
  ];

  initialize() {
    this.toggleSuggestion();
    this.updateVisibility();
    initChoices();
  }

  toggleSuggestion(event) {
    if (this.hasCapabilitiesTarget) {
      const target = this.capabilitiesTarget;

      if (
        Array.from(target.selectedOptions)
          .map((x) => x.text)
          .includes("Other")
      ) {
        this.suggestionTarget.classList.remove("d-none");
      } else {
        this.suggestionTarget.classList.add("d-none");
      }
    }
  }

  toggleCounter(event) {
    const target = this.counterTarget;
    event.target.value == "true" ? target.classList.remove("d-none") : target.classList.add("d-none");
  }

  updateVisibility() {
    function doShowOrDisable(el, show) {
      if (show) {
        el.classList.remove("d-none");
      } else {
        el.classList.add("d-none");
      }
      el.querySelectorAll("input, select").forEach((el) => {
        if (show) {
          el.removeAttribute("disabled");
        } else {
          el.setAttribute("disabled", "disabled");
        }
      });
    }

    const currentOption = this.hasOrderTypeTarget ? this.orderTypeTargets.find((el) => el.checked) : null;
    const valueCheck =
      typeof currentOption === "undefined" || currentOption === null ? false : currentOption.value === "order_required";
    const isOrderRequired = !this.hasOrderTypeTarget || valueCheck;
    const isInternal = this.hasInternalTarget && this.internalTarget.checked;

    if (this.hasInternalTarget) {
      doShowOrDisable(this.internalWrapperTarget, isOrderRequired);
      doShowOrDisable(this.internalDescriptionTarget, isOrderRequired);
    }

    const hasRelatedTraining = this.hasTrainingTarget && this.trainingTarget.checked;
    if (this.hasTrainingTarget) {
      doShowOrDisable(this.trainingWrapperTarget, hasRelatedTraining);
    }
    if (this.hasOrderUrlWrapperTarget) {
      doShowOrDisable(this.orderUrlWrapperTarget, !(isOrderRequired && isInternal));
      doShowOrDisable(document.getElementById("order-url-hint"), !(isOrderRequired && isInternal));
    }
    if (this.hasPrimaryOmsWrapperTarget) {
      doShowOrDisable(this.primaryOmsWrapperTarget, isOrderRequired && isInternal);
    }

    if (this.hasPrimaryOmsTarget) {
      const selectedId = this.primaryOmsTarget.value;
      const shouldShow =
        isOrderRequired && isInternal && !!selectedId
          ? (el) => el.getAttribute("data-oms-id") === selectedId
          : () => false;
      this.omsParamsContainerTarget.querySelectorAll("[data-oms-id]").forEach((el) => {
        doShowOrDisable(el, shouldShow(el));
      });
    }
  }
}
