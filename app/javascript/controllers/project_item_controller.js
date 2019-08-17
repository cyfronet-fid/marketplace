import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["project", "projectDetails",
                    "hasVoucher", "iHaveVaucher", "iDontHaveVoucher"];

  connect() {
  }

  initialize() {
    this._fetchProjectData(this.projectTarget.value)
  }

  projectChanged(event) {
    this._fetchProjectData(event.target.value)
  }

  _fetchProjectData(project_id) {
    if (project_id) {
      fetch(`${this.data.get("url")}/${project_id}`,
            { headers: { "X-Requested-With": "XMLHttpRequest" }})
        .then(response => response.text())
        .then(html => this.projectDetailsTarget.innerHTML = html)
    }
  }

  voucherChanged(event) {
    if(event.currentTarget.value === "false") {
      this.hasVoucherTarget.classList.remove('hidden-fields');
      this.iHaveVoucherTarget.classList.add("active");
      this.iDontHaveVoucherTarget.classList.remove("active");
    } else {
      this.hasVoucherTarget.classList.add('hidden-fields');
      this.iHaveVoucherTarget.classList.remove("active");
      this.iDontHaveVoucherTarget.classList.add("active");
    }
  }
}
