import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["idSource", "details", "empty", "projects"];

  connect() {
    this._fetchDetails(this.idSourceTarget.value);
  }

  changed(event) {
    this._fetchDetails(event.target.value);
    if (event.target.value) {
      if (this.hasProjectsTarget) {
        this.projectsTarget.classList.remove("d-none");
        this.emptyTarget.classList.add("d-none");
      }
    }
  }

  _fetchDetails(id) {
    if (id) {
      fetch(`${this.data.get("url")}/${id}`, { headers: { "X-Requested-With": "XMLHttpRequest" } })
        .then((response) => response.text())
        .then((html) => (this.detailsTarget.innerHTML = html));
    }
  }
}
