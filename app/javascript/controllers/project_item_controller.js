import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["reason", "customer"];

  connect() {
  }

  projectChanged(event) {
    fetch("/projects/" + event.target.value, { dataType: "json" })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("unable to fetch project details");
      })
      .then(project => this._setProjectDefaults(project))
      .catch(error => console.log(error.message));
  }

  _setProjectDefaults(project) {
    this.reasonTarget.value = project["reason_for_access"];
    this.customerTarget.value = project["customer_typology"];
  }
}
