import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["array", "input", "publicContacts", "publicContact",
    "destroy", "addContact", "multimedia", "changelog", "grantProjectNames",
    "certifications", "standards", "openSourceTechnologies", "useCasesUrl",
    "relatedPlatforms"]

  initialize(){
  }

  addNewArrayField(event) {
    event.preventDefault();
    const lastArrayField = document.createElement("textarea");
    const parentName = event.target.dataset.wrapper;
    const parent = document.getElementsByClassName(parentName)[0];

    lastArrayField.name = event.target.dataset.name;
    lastArrayField.id = parentName + "_" + (parent.getElementsByTagName("textarea").length);
    lastArrayField.classList = event.target.dataset.class;

    const removeLink = document.createElement("a");

    const linkText = document.createTextNode("Remove")

    removeLink.id = "remove_" + lastArrayField.id;
    removeLink.dataset.target= event.target;
    removeLink.dataset.action= "click->service#removeField";
    removeLink.dataset.value= lastArrayField.id;
    removeLink.appendChild(linkText);
    removeLink.classList.add("btn", "btn-danger");

    parent.appendChild(lastArrayField);
    parent.appendChild(removeLink);
  }

  removeField(event) {
    event.preventDefault();
    document.getElementById(event.target.dataset.value).remove();
    event.target.remove();
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
