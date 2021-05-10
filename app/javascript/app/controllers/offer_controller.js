import {Controller} from 'stimulus'
import initChoises from "../choises";

export default class extends Controller {
  static targets = ["parameters", "webpage", "external",
                    "attributes", "button", "attributeType",
                    "orderType", "internal", "primaryOms",
                    "internalWrapper", "orderUrlWrapper", "primaryOmsWrapper",
                    "omsParamsContainer"];

  initialize() {
    this.indexCounter = 0;
    if (this.attributesTarget.firstElementChild) {
      this.attributesTarget.classList.add("active");
    }
    this.updateVisibility();
  }

  add(event) {
    const template = this.buttonTarget.dataset.template
      .replace(/js_template_id/g, this.generateId());
    const newElement = document.createRange().createContextualFragment(template).firstChild;

    this.attributesTarget.appendChild(newElement);
    initChoises(newElement);

    this.buttonTarget.disabled = true;
    this.fromArrayRemoveSelect();
    this.attributesTarget.classList.add("active");
    this.buttonTarget.classList.remove("active");
  }

  generateId() {
    return new Date().getTime()%10000 + this.indexCounter++;
  }

  remove(event) {
    event.target.closest(".parameter-form").remove();
    if (!this.attributesTarget.firstElementChild) {
      this.attributesTarget.classList.remove("active");
    }
  }

  selectParameterType(event){
    const template = event.target.dataset.template
    this.buttonTarget.disabled = false
    this.setSelect(event)
    this.buttonTarget.dataset.template = template
    this.buttonTarget.classList.add("active");
  }

  setSelect(event){
    this.fromArrayRemoveSelect();
    event.target.classList.add("selected")
  }

  fromArrayRemoveSelect() {
    this.attributeTypeTargets.forEach(this.removeSelect)
  }

  removeSelect(elem, index) {
    elem.classList.remove("selected")
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

    const isOrderRequired = this.orderTypeTarget.value === "order_required";
    const isInternal = this.internalTarget.checked;
    doShowOrDisable(this.internalWrapperTarget, isOrderRequired);
    doShowOrDisable(this.orderUrlWrapperTarget, isOrderRequired && !isInternal);
    doShowOrDisable(this.primaryOmsWrapperTarget, isOrderRequired && isInternal);

    const selectedId = this.primaryOmsTarget.value;
    const shouldShow = (isOrderRequired && isInternal && !!selectedId) ?
        (el) => el.getAttribute("data-oms-id") === selectedId : () => false;
    this.omsParamsContainerTarget.querySelectorAll("[data-oms-id]").forEach(el => {
      doShowOrDisable(el, shouldShow(el));
    });
  }
}
