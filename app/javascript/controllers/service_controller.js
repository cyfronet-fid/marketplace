import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["connectedUrl", "serviceType"]

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
}
