import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["publicContacts", "publicContact", "destroy", "addContact"]

  initialize(){
  }

  addContact(event){
    event.preventDefault();
    event.target.insertAdjacentHTML('beforebegin',
        event.target.dataset.fields.replace(/new_field/g, this.publicContactTargets.length));
  }

  removeContact(event){
    event.preventDefault();
    event.target.parentElement.previousElementSibling.value = "true";
    event.target.closest(".contact").classList.add("d-none");
  }
}
