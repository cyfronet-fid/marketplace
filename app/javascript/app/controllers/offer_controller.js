import { Controller } from "stimulus";
import initChoices from "../choices";

export default class extends Controller {
  static targets = ["parameters", "external", "attributes", "button", "attributeType"];

  initialize() {
    this.indexCounter = 0;
    if (this.attributesTarget.firstElementChild) {
      this.attributesTarget.classList.add("active");
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
}
