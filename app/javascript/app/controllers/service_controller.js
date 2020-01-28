import { Controller } from "stimulus"


export default class extends Controller {
  static targets = ["contactEmails"]

  initialize(){
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
