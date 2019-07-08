import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["reason", "usage", "customerCountry", "customer",
                    "privateCompany", "collaborationCountry",
                    "userGroupName", "projectName",
                    "projectWebsiteUrl", "companyName",
                    "companyWebsiteUrl", "hasVoucher",
                    "email", "organization", "department", "webpage",
                    "iDontHaveVoucher", "iHaveVoucher", "project",
                    "additionalInformation"];

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
    this.usageTarget.innerHTML = "Usage"
    this.reasonTarget.innerHTML = this._wrap_text(project["reason_for_access"], "Access reason");
    this.customerCountryTarget.innerHTML =
        this._wrap_text(this._getCountriesNames(project["country_of_customer"]),"Customer country");
    this.customerTarget.innerHTML = this._wrap_text(project["customer_typology"], "Customer typology");
    this.collaborationCountryTarget.innerHTML =
        project["country_of_collaboration"].length ?
        this._wrap_text(this._getCountriesNames(project["country_of_collaboration"]), "Country of collaboration") : "";
    this.userGroupNameTarget.innerHTML = this._wrap_text(project["user_group_name"], "User group name");
    this.projectNameTarget.innerHTML = this._wrap_text(project["project_name"], "Project name");
    this.projectWebsiteUrlTarget.innerHTML = this._wrap_text(project["project_website_url"], "Project website url");
    this.companyNameTarget.innerHTML = this._wrap_text(project["company_name"], "Company name");
    this.companyWebsiteUrlTarget.innerHTML = this._wrap_text(project["company_website_url"], "Company website url");
    this.additionalInformationTarget.innerHTML = this._wrap_text(project["additional_information"], "Additional Information");

    this.emailTarget.innerHTML = this._wrap_text(project["email"], "Email");
    this.organizationTarget.innerHTML = this._wrap_text(project["organization"], "Organization");
    this.departmentTarget.innerHTML = this._wrap_text(project["department"], "Department");
    this.webpageTarget.innerHTML = this._wrap_text(project["webpage"], "Webpage");
  }

  _wrap_text(text, label) {
    return text && "<h4>" + label + "</h4> <p>" + text + "</p>";
  }

  _getCountriesNames(codes) {
    const countries = require("i18n-iso-countries");
    countries.registerLocale(require("i18n-iso-countries/langs/en.json"));

    let result = "";
    if(!Array.isArray(codes)) {
      codes = [codes]
    }
    for (const [idx, alpha2] of codes.entries()) {
      switch (alpha2) {
        case "N/E":
          result += "non-European";
          break;
        case "N/A":
          result += "non Applicable";
          break;
        case "I/N":
          result += "International";
        default:
          result += countries.getName(alpha2, "en");
      }
      if (idx === codes.length -1 ) {
        return result;
      }
      else {
        result += ", ";
      }
    };
  }


}
