import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["reason", "usage", "originCountry", "customer", "customerDetails",
                    "privateCompany", "partnershipCountries",
                    "userGroupName", "projectName", "researchAreas",
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
    this.usageTarget.innerHTML = "Usage";
    this.customerDetailsTarget.innerHTML = "Customer details";
    this.reasonTarget.innerHTML = this._wrap_text(project["reason_for_access"], "Access reason");
    this.researchAreasTarget.innerHTML =
        this._wrap_text(this._getResearchAreasNames(project["research_areas"]) || "Not specified", "Research Areas");
    this.additionalInformationTarget.innerHTML = this._wrap_text(project["additional_information"], "Additional Information");
    this.customerTarget.innerHTML = this._wrap_text(project["customer_typology"], "Customer typology");
    this.originCountryTarget.innerHTML =
        this._wrap_text(this._getCountriesNames(project["country_of_origin"]),"Customer country");
    this.partnershipCountriesTarget.innerHTML =
        this._wrap_text(this._getCountriesNames(project["countries_of_partnership"]), "Country of collaboration");
    this.userGroupNameTarget.innerHTML = this._wrap_text(project["user_group_name"], "User group name");
    this.projectNameTarget.innerHTML = this._wrap_text(project["project_name"], "Project name");
    this.projectWebsiteUrlTarget.innerHTML = this._wrap_text(project["project_website_url"], "Project website url");
    this.companyNameTarget.innerHTML = this._wrap_text(project["company_name"], "Company name");
    this.companyWebsiteUrlTarget.innerHTML = this._wrap_text(project["company_website_url"], "Company website url");
        this.emailTarget.innerHTML = this._wrap_text(project["email"], "Email");
    this.organizationTarget.innerHTML = this._wrap_text(project["organization"], "Organization");
    this.departmentTarget.innerHTML = this._wrap_text(project["department"], "Department");
    this.webpageTarget.innerHTML = this._wrap_text(project["webpage"], "Webpage");
  }

  _wrap_text(text, label) {
    return text && "<h4>" + label + "</h4> <p>" + text + "</p>";
  }

  _getCountriesNames(countries) {
    let result = "";
    if(!Array.isArray(countries)) {
      countries = [countries]
    }
    for (const [idx, country] of countries.entries()) {
      if(!country) {
        return result = null;
      }
      result += country.data.name
      if (idx === countries.length -1 ) {
        return result;
      }
      else {
        result += ", ";
      }
    }
  }

  _getResearchAreasNames(areas) {
    let result = "";
    for (const [idx, area] of areas.entries()) {
      result += area.name;
      if (idx === areas.length -1 ) {
        return result;
      }
      else {
        result += ", ";
      }
    }
  }


}
