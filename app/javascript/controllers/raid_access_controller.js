import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["accessType", "embargoExpiry", "embargoExpiryInput"];

  connect() {
    console.log("Raid access controller connected");
    this.embargoExpiry = this.embargoExpiryTarget;
    this.embargoExpiry.hidden = true;
    this.embargoExpiry = "";
  }

  setEmbargoed() {
    const accessType = this.accessTypeTarget.value;
    this.embargoExpiryInput = this.embargoExpiryInputTarget;

    if (this.embargoExpiry == "") {
      this.embargoExpiry = this.embargoExpiryInput.value;
    }

    if (accessType == "embargoed") {
      this.embargoExpiryTarget.hidden = false;
      this.embargoExpiryInput.value = this.embargoExpiry;
    } else {
      this.embargoExpiryTarget.hidden = true;
      this.embargoExpiryInput.value = "";
    }
  }
}
