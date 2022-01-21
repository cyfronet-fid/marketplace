import { ResourcesFactory } from "../../../../factories/resource.factory";
import { OfferFactory } from "../../../../factories/resource.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { ParametersFactory } from "../../../../factories/resource.factory";

describe("Owned resources", () => {
  const user = UserFactory.create({roles: ["service_portfolio_manager"]});
  const [resource, resource2, resource3, resource4, resource5] = [...Array(5)].map(() =>
    ResourcesFactory.create()
  );
  const offer = OfferFactory.create();
  const parameter = ParametersFactory.create();
  const correctLogo = "logo.jpg"
  const wrongLogo = "logo.svg"
 
  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });
  
  it("should go to Owned resources in Backoffice and select one of resources", () => {
    cy.get("[data-e2e='my-eosc-button']")
      .click();
    cy.get("[data-e2e='backoffice']")
      .click();
    cy.location("href")
      .should("contain", "/backoffice");
    cy.get("[data-e2e='owned-resources']")
      .click();
    cy.location("href")
      .should("contain", "/backoffice/services")
    cy.get("[data-e2e='service-id'] a")
      .eq(0)
      .click()
    cy.contains("a","Edit resource")
      .should("be.visible")   
  });

  it("should add new resource and published it", () => {
    cy.visit("/backoffice")
    cy.get("[data-e2e='owned-resources']")
      .click();
    cy.get("[data-e2e='create-resource']")
      .click();
    cy.location("href")
      .should("contain", "/services/new")
    cy.fillFormCreateResource(resource, correctLogo);
    cy.get("[data-e2e='submit-btn']").click()
    cy.contains("div.alert-success", "New resource created successfully")
      .should("be.visible");
    cy.contains("a","Edit resource")
      .should("be.visible") 
    cy.contains("a","Set parameters and offers")
      .should("be.visible")  
    cy.contains("span", "draft")
      .should("be.visible") 
    cy.get("[data-e2e='publish-btn']")
      .click();
    cy.contains("span", "published")
      .should("be.visible")
    cy.get(".service-details-header h2")
      .invoke("text")
      .then(value=>{
        cy.visit("/")
        cy.get("[data-e2e='searchbar-input']")
          .type(value);
        cy.get("[data-e2e='query-submit-btn']")
          .click();
        cy.get("[data-e2e='service-name']")
          .should("include.text", value);
        cy.contains("[data-e2e='service-name']", value)
          .click()
        cy.get("[data-e2e='access-resource-btn']")
          .should("be.visible");
    });
  });

  it("shouldn't add new resource", ()=> {
    cy.visit("/backoffice/services/new")
    cy.fillFormCreateResource({...resource, basicWebpage_url:"wrongFormat", contactsEmail:"wrongFormat"}, wrongLogo);
    cy.get("[data-e2e='submit-btn']")
      .click();
    cy.get("div.invalid-feedback")
      .should("be.visible")
    cy.contains("div.invalid-feedback", "Logo is not a valid file format and Logo format you're trying to attach is not supported")
      .should("be.visible")
    cy.contains("div.invalid-feedback", "Email is not a valid email address")
      .should("be.visible")
    cy.contains("div.invalid-feedback", "Webpage url is not a valid URL")
      .should("be.visible"); 
  });

  it("should add new offers", ()=>{
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource2, correctLogo);
    cy.get("[data-e2e='submit-btn']")
      .click();
    cy.get("[data-e2e='add-new-offer-btn']")
      .click();
    cy.fillFormCreateOffer(offer)
    cy.get("[data-e2e='create-offer-btn']")
      .click();
    cy.get("[data-e2e='offer']")
      .should("have.length", 2);
    cy.get("[data-e2e='offer'] .badge")
      .eq(1)
      .should("include.text", "Order required")

    cy.get("[data-e2e='add-new-offer-btn']")
      .click();
    cy.fillFormCreateOffer({...offer, orderType:"open_access"})
    cy.get("[data-e2e='create-offer-btn']")
      .click();
    cy.get("[data-e2e='offer']")
      .should("have.length", 3);
    cy.get("[data-e2e='offer'] .badge")
      .eq(2)
      .should("include.text", "Open Access")

    cy.get("[data-e2e='add-new-offer-btn']")
      .click();
    cy.fillFormCreateOffer({...offer, internalOrder:true})
    cy.fillFormCreateParameter(parameter)
    cy.get("[data-e2e='create-offer-btn']")
      .click();
    cy.get("[data-e2e='offer']")
      .should("have.length", 4);
    cy.get("[data-e2e='offer'] .badge")
      .eq(3)
      .should("include.text", "Order required")

    cy.get("[data-e2e='publish-btn']")
      .click();
    cy.get(".service-details-header h2")
      .invoke("text")
      .then(value=>{
        cy.visit("/")
        cy.get("[data-e2e='searchbar-input']")
          .type(value);
        cy.get("[data-e2e='query-submit-btn']")
          .click();
        cy.get("[data-e2e='service-name']")
          .should("include.text", value);
        cy.contains("[data-e2e='service-name']", value)
          .click()
        cy.get("[data-e2e='access-resource-btn']")
          .should("be.visible");
        cy.get("[data-e2e='select-offer-btn']")
          .eq(1)
          .click();
        cy.contains("a", "Go to the order website")
        cy.contains("a", "Configuration")
          .should("not.exist")
        cy.go("back")
        cy.get("[data-e2e='select-offer-btn']")
          .eq(2)
          .click();
        cy.contains("a", "Go to the resource")
          .should("be.visible")
        cy.contains("a", "Configuration")
          .should("not.exist")
        cy.go("back")
        cy.get("[data-e2e='select-offer-btn']")
            .eq(3)
            .click();
        cy.contains("p", "ordered via EOSC Marketplace")
          .should("be.visible")
        cy.contains("a", "Configuration")
          .should("be.visible")
    });
  });

  it("should go to Preview mode, back to edit and create resource", ()=> {
    cy.visit("/backoffice/services/new")
    cy.fillFormCreateResource(resource3, correctLogo);
    cy.get("[data-e2e='preview-btn']")
      .click();
    cy.contains("div", "Service preview")
      .should("be.visible")
    cy.get("[data-e2e='go-back-edit-btn']")
      .click();
    cy.get("[data-e2e='submit-btn']")
      .click()
    cy.contains("div.alert-success", "New resource created successfully")
      .should("be.visible");
    cy.contains("a","Edit resource")
      .should("be.visible") 
    cy.contains("a","Set parameters and offers")
      .should("be.visible")   
  });

  it("should go to Preview mode and confirm changes", ()=> {
    cy.visit("/backoffice/services/new")
    cy.fillFormCreateResource(resource4, correctLogo);
    cy.get("[data-e2e='preview-btn']")
      .click();
    cy.contains("div", "Service preview")
      .should("be.visible")
    cy.get("[data-e2e='confirm-changes-btn']")
      .click();
    cy.contains("div.alert-success", "New resource created successfully")
      .should("be.visible");
    cy.contains("a","Edit resource")
      .should("be.visible");
    cy.contains("a","Set parameters and offers")
      .should("be.visible");
  });

  it("shouldn't go to Preview mode with wrong data format", ()=> {;
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource({...resource, basicWebpage_url:"wrongFormat", contactsEmail:"wrongFormat"}, correctLogo);
    cy.get("[data-e2e='preview-btn']")
      .click();
    cy.contains("div.invalid-feedback", "Email is not a valid email address")
        .should("be.visible");
    cy.contains("div.invalid-feedback", "Webpage url is not a valid URL")
      .should("be.visible");
  });

  it("shouldn't go to Preview mode with wrong logo", ()=> {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource5, wrongLogo);
    cy.get("[data-e2e='preview-btn']")
      .click();
    cy.contains(
      "div.invalid-feedback",
      "Logo format you're trying to attach is not supported. " +
      "Supported formats: png, gif, jpg, jpeg, pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon")
      .should("be.visible");
  });
});

