import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["customer", "research", "customerCountry",
                    "collaborationCountry", "project", "privateCompany",
                    "input"];

  connect() {
  }

  initialize() {
    this.CUSTOMER_TYPOLOGIES = { single_user: "single_user",
                                research: "research",
                                private_company: "private_company",
                                project: "project" }
    this.showSelectedSection();
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
    if (customer !== "" && customer !== this.CUSTOMER_TYPOLOGIES.single_user){
       this.collaborationCountryTarget.classList.remove("hidden-fields")
    }
  }

  _hideCustomerTypologieFields() {
    this.inputTargets.forEach((el, i) => {
      if(!el.classList.contains("hidden-fields")){
        el.classList.add("hidden-fields");
      }
    })
  }
}
