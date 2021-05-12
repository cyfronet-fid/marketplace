import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = [
    "orderType",
    "internal",
    "internalWrapper",
    "primaryOms",
    "primaryOmsWrapper",
    "orderUrlWrapper",
    "omsParamsContainer"
  ];

  initialize() {
    this.updateVisibility();
  }

  updateVisibility() {
    function doShowOrDisable(el, show) {
      if (show) {
        el.classList.remove("hidden-fields");
      } else {
        el.classList.add("hidden-fields");
      }
      el.querySelectorAll("input, select").forEach(el => {
        if (show) {
          el.removeAttribute("disabled");
        } else {
          el.setAttribute("disabled", "disabled");
        }
      });
    }

    const isOrderRequired =
        // The undefined case is that of a default offer with order_type=order_required,
        // for order_type!=order_required this controller shouldn't be registered at all.
        !this.hasOrderTypeTarget ||
        this.orderTypeTarget.value === "order_required";
    const isInternal = this.internalTarget.checked;

    doShowOrDisable(this.internalWrapperTarget, isOrderRequired);

    if (this.hasOrderUrlWrapperTarget) {
      doShowOrDisable(this.orderUrlWrapperTarget, !(isOrderRequired && isInternal));
    }

    doShowOrDisable(this.primaryOmsWrapperTarget, isOrderRequired && isInternal);

    const selectedId = this.primaryOmsTarget.value;
    const shouldShow = (isOrderRequired && isInternal && !!selectedId) ?
        (el) => el.getAttribute("data-oms-id") === selectedId : () => false;
    this.omsParamsContainerTarget.querySelectorAll("[data-oms-id]").forEach(el => {
      doShowOrDisable(el, shouldShow(el));
    });
  }
}
