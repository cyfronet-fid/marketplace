import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["array", "input", "publicContacts", "publicContact",
    "destroy", "addContact"]

  initialize(){
  }

  addNewArrayField(event) {
    event.preventDefault()
    const lastArrayField = document.createElement("textarea")
    const parent = this.arrayTarget

    lastArrayField.name = this.inputTarget.name
    lastArrayField.id = this.inputTarget.id.slice(0, -1) + (parent.children.length - 1)
    lastArrayField.classList = this.inputTarget.classList

    parent.appendChild(lastArrayField)
  }

  clearEmptyFields(event){
    for (let i = 0; i < this.arrayTarget.childElementCount; i++) {
      var el = this.arrayTarget.children[i]
      if(!el.value)
        this.arrayTarget.children[i].remove()
    }
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
