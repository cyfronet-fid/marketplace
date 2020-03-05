import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ["parameters", "webpage", "offerType", "attributes"];

  initialize() {
    this.showWebpage();
  }

  addAttribute(event) {
    const frag = document.createRange()
      .createContextualFragment(event.target.dataset.template);
    this.attributesTarget.appendChild(frag.firstChild);
  }

  removeAttribute(event) {
    event.target.closest(".card").remove();
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
