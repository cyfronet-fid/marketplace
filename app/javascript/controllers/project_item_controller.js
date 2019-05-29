import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["reason", "customer","privateCompany",
                    "userGroupName", "projectName",
                    "projectWebsiteUrl", "companyName",
                    "companyWebsiteUrl", "hasVoucher",
                    "iDontHaveVoucher", "iHaveVoucher", "project"];

  connect() {
  }

  initialize() {
    this.CUSTOMER_TYPOLOGIES = { single_user: "single_user",
                                research: "research",
                                private_company: "private_company",
                                project: "project" }
    this.fetchProjectData(this.projectTarget.value)
  }

  projectChanged(event) {
    this.fetchProjectData(event.target.value)
  }

  fetchProjectData(value) {
    if (value){
      Rails.ajax({
        url: this.data.get("url") + "/" + value,
        type: "get",
        dataType: "json",
        success: this._success.bind(this),
        error: this._error.bind(this)
      })
    }
  }

  _success(response) {
    this._showProjectFields(response);
  }

  _error(error){
    console.log(error.message);
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

  _showProjectFields(project) {
    this.reasonTarget.innerHTML = this._wrap_text(project["reason_for_access"], "Access reason");
    this.customerTarget.innerHTML = this._wrap_text(project["customer_typology"], "Customer typology")
    this.userGroupNameTarget.innerHTML = this._wrap_text(project["user_group_name"], "User group name");
    this.projectNameTarget.innerHTML = this._wrap_text(project["project_name"], "Project name");
    this.projectWebsiteUrlTarget.innerHTML = this._wrap_text(project["project_website_url"], "Project website url");
    this.companyNameTarget.innerHTML = this._wrap_text(project["company_name"], "Company name");
    this.companyWebsiteUrlTarget.innerHTML = this._wrap_text(project["company_website_url"], "Company website url");
  }

  _wrap_text(text, label) {
    return text && "<h4>" + label + "</h4> <p>" + text + "</p>";
  }
}
