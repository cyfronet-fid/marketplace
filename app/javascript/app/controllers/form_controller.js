import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["array", "form", "input", "publicContacts", "publicContact",
    "destroy", "addContact", "multimedia", "changelog", "grantProjectNames",
    "certifications", "standards", "openSourceTechnologies", "useCasesUrl",
    "relatedPlatforms", "affiliations", "national_roadmaps", "fixme", "tag_list"]

  initialize() {
    this.addListenersForCollapse();
    this.disableFormButtons();
  }

  onScroll(event) {
    const titlePosition = document.getElementById("title").offsetTop;
    const footerPosition = document.getElementsByTagName("footer")[0].offsetTop;
    if (window.scrollY > titlePosition && window.scrollY < (footerPosition - 500)) {
      this.fixmeTarget.style.position = "fixed";
      this.fixmeTarget.style.top = "10px";
    } else if (window.scrollY > (footerPosition - 750)) {
      this.fixmeTarget.style.position = "absolute";
      this.fixmeTarget.style.top = (footerPosition - 750) + "px";
    } else {
      this.fixmeTarget.style.position = "static";
    }
  }

  disableFormButtons() {
    if (this.formTarget.dataset.disabled === "true") {
      const elements = document.getElementsByClassName("disablable");
      console.log(elements);
      for (let i = 0; i<elements.length; i++) {
        elements[i].classList.add("disabled");
      }
    }
  }

  addListenersForCollapse() {
    // TODO: change this function if bootstrap events will be enabled without jQuery
    $(".accordion").find(".collapse").on('shown.bs.collapse', function () {
      this.previousElementSibling.scrollIntoView({ behavior: "smooth" });
    })
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
    removeLink.dataset.action= "click->form#removeField";
    removeLink.dataset.value= lastArrayField.id;
    removeLink.appendChild(linkText);
    removeLink.classList.add("btn-sm", "btn-danger", "remove", "float-right");

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
