import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["idSource", "details"];

  connect() {
    this._fetchDetails(this.idSourceTarget.value);
  }

  changed(event) {
    this._fetchDetails(event.target.value)
  }

  _fetchDetails(id) {
    if (id) {
      fetch(`${this.data.get("url")}/${id}`,
            { headers: { "X-Requested-With": "XMLHttpRequest" }})
        .then(response => response.text())
        .then(html => this.detailsTarget.innerHTML = html)
    }
  }
}
