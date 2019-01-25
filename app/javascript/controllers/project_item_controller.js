import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["reason", "customer", "research",
                    "project", "privateCompany", "input",
                    "userGroupName", "projectName",
                    "projectWebsiteUrl", "companyName",
                    "companyWebsiteUrl", "hasVoucher",
                    "iDontHaveVoucher", "iHaveVoucher"];

  connect() {
   }

  initialize(){
   this.CUSTOMER_TYPOLOGIES = { "single_user": "single_user",
                               "research": "research",
                               "private_company" : "private_company",
                               "project" : "project" }
   this.showSelectedSection();
  }

  projectChanged(event) {
    fetch(this.data.get("url") + "/" + event.target.value, { dataType: "json" })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
        throw new Error("unable to fetch project details");
      })
      .then(project => {
        this._setProjectDefaults(project);
        this.showSelectedSection();
      })
      .catch(error => console.log(error.message));
  }

  showSelectedSection(){
    const customer  = this.customerTarget.value

    this._hideCustomerTypologieFields();

    if ( customer === this.CUSTOMER_TYPOLOGIES.research){
      this.researchTargets.forEach ((el, i) => {
        el.classList.remove("hidden-fields");
      })
    }
    if (customer === this.CUSTOMER_TYPOLOGIES.project){
      this.projectTargets.forEach ((el, i) => {
        el.classList.remove("hidden-fields");
      })
    }
    if (customer === this.CUSTOMER_TYPOLOGIES.private_company){
      this.privateCompanyTargets.forEach ((el, i) => {
        el.classList.remove("hidden-fields");
      })
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

  _hideCustomerTypologieFields() {
    this.inputTargets.forEach((el, i) => {
      if(!el.classList.contains("hidden-fields")){
        el.classList.add("hidden-fields");
      }
    })
  }

  _setProjectDefaults(project) {
    this.reasonTarget.value = project["reason_for_access"];
    this.customerTarget.value = project["customer_typology"];
    this.userGroupNameTarget.value = project["user_group_name"];
    this.projectNameTarget.value = project["project_name"];
    this.projectWebsiteUrlTarget.value = project["project_website_url"];
    this.companyNameTarget.value = project["company_name"];
    this.companyWebsiteUrlTarget.value = project["company_website_url"];
  }
}
