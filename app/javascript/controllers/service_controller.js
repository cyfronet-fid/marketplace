import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["connectedUrl", "serviceType", "contactEmails"]

  connect(){}

  initialize(){
    this.showConnectedUrl()
  }

  showConnectedUrl(event){
    const serviceType = this.serviceTypeTarget.value
    if (serviceType == "open_access"){
      this.connectedUrlTarget.classList.remove("hidden-fields");
    } else {
      this.connectedUrlTarget.classList.add("hidden-fields");
    }
  }

  addNewEmailField(event) {
    event.preventDefault()
    var lastEmailField = document.createElement("input")
    var parent = this.contactEmailsTarget
    lastEmailField.type = "email"
    lastEmailField.name = "service[contact_emails][]"
    lastEmailField.id = "service_contact_emails_"+(parent.children.length - 1)

    parent.appendChild(lastEmailField)
  }

  clearEmptyEmails(event){
    for (let i = 0; i < this.contactEmailsTarget.childElementCount; i++) {
      var el = this.contactEmailsTarget.children[i]
      if(el.type === "email" && !el.value)
        this.contactEmailsTarget.children[i].remove()
    }
  }
}
