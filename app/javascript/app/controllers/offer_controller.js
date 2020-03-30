import {Controller} from 'stimulus'
import initChoises from "../choises";

export default class extends Controller {
  static targets = ["parameters", "webpage", "offerType",
                    "attributes", "button", "attributeType"];

  initialize() {
    this.showWebpage();
    this.indexCounter = 0;
  }

  add(event) {
    const template = this.buttonTarget.dataset.template
      .replace(/js_template_id/g, this.generateId());
    const newElement = document.createRange().createContextualFragment(template).firstChild;

    this.attributesTarget.appendChild(newElement);
    initChoises(newElement);

    this.buttonTarget.disabled = true;
    this.fromArrayRemoveSelect();
  }

  generateId() {
    return new Date().getTime() + this.indexCounter++;
  }

  remove(event) {
    event.target.closest(".parameter-form").remove();
    this.attributesTarget.classList.remove("active");
  }

  selectParameterType(event){
    const template = event.target.dataset.template
    this.buttonTarget.disabled = false
    this.setSelect(event)
    this.buttonTarget.dataset.template = template
    this.buttonTarget.classList.add("active");
    this.attributesTarget.classList.add("active");
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
    const previous = current.previousSibling;

    if (previous != undefined) {
      current.parentNode.insertBefore(current, previous);
    }
  }

  down(event) {
    const current = event.target.closest(".parameter-form");
    const next = current.nextSibling;

    if (next != undefined) {
      current.parentNode.insertBefore(next, current);
    }
  }

  showWebpage(event){
    const offerType = this.offerTypeTarget.value
    if (offerType == "external" || offerType == "open_access"){
      this.webpageTarget.classList.remove("hidden-fields");
    } else {
      this.webpageTarget.classList.add("hidden-fields");
    }
  }
}
