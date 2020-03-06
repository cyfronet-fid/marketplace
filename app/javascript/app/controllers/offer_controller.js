import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ["parameters", "webpage", "offerType", "attributes"];

  initialize() {
    this.showWebpage();
    this.indexCounter = 0;
  }

  addAttribute(event) {
    const template = event.target.dataset.template
      .replace(/js_template_id/g, this.generateId());
    const frag = document.createRange().createContextualFragment(template);

    this.attributesTarget.appendChild(frag.firstChild);
  }

  generateId() {
    return new Date().getTime() + this.indexCounter++;
  }

  removeAttribute(event) {
    event.target.closest(".parameter-form").remove();
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
