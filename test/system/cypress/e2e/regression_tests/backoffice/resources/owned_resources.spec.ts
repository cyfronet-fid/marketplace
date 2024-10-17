import { ResourcesFactory, ResourcesFactoryExtended } from "../../../../factories/resource.factory";
import { OfferFactory } from "../../../../factories/resource.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { ParametersFactory } from "../../../../factories/resource.factory";
import { ResourceMessages } from "../../../../fixtures/messages";

describe("Owned services", () => {
  const user = UserFactory.create({ roles: ["service_portfolio_manager"] });
  const [resource, resource2, resource3, resource4, resource5, resource6] = [...Array(6)].map(() =>
    ResourcesFactory.create(),
  );
  const [resourceExtented] = [...Array(1)].map(() => ResourcesFactoryExtended.create());
  const message = ResourceMessages;

  const offer = OfferFactory.create();
  const parameter = ParametersFactory.create();

  const correctLogo = "logo.jpg";
  const wrongLogo = "logo.svg";

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  it("should go to Owned services in Backoffice and select one of services", () => {
    cy.openUserDropdown();
    cy.get("[data-e2e='backoffice']").click();
    cy.location("href").should("contain", "/backoffice");
    cy.get("[data-e2e='owned-services']").click();
    cy.location("href").should("contain", "/backoffice/services");
    cy.get("[data-e2e='service-id'] a").eq(1).click();
    cy.contains("a", "Edit service").should("be.visible");
  });

  it("should add new service and publish it", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource, correctLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.contains("a", "Edit service").should("be.visible");
    cy.contains("a", "Set parameters and offers").should("be.visible");
    cy.contains("span", "unpublished").should("be.visible");
    cy.get("[data-e2e='publish-btn']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("span", "published").should("be.visible");
    cy.get(".service-details-header h2")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='query-submit-btn']").click();
        cy.get("[data-e2e='service-name']").should("include.text", value);
        cy.contains("[data-e2e='service-name']", value).click();
        cy.get("[data-e2e='access-service-btn']").should("not.exist");
      });
  });

  it("shouldn't add new service", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource({ ...resource, basicWebpage_url: "wrongFormat", contactEmail: "wrongFormat" }, wrongLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("div.invalid-feedback").should("be.visible");
    cy.contains("div.invalid-feedback", message.alertLogoValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertEmailValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertUrlValidation).should("be.visible");
  });

  it.skip("should add new offers", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource2, correctLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("[data-e2e='add-new-offer-btn']").click();
    cy.fillFormCreateOffer(offer);
    cy.get("[data-e2e='create-offer-btn']").click();
    cy.get("[data-e2e='offer']").should("have.length", 2);
    cy.get("[data-e2e='offer'] .badge-right").eq(1).should("include.text", "Order required");

    cy.get("[data-e2e='add-new-offer-btn']").click();
    cy.fillFormCreateOffer({ ...offer, orderType: "open_access" });
    cy.get("[data-e2e='create-offer-btn']").click();
    cy.get("[data-e2e='offer']").should("have.length", 3);
    cy.get("[data-e2e='offer'] .badge-right").eq(2).should("include.text", "Open Access");

    cy.get("[data-e2e='add-new-offer-btn']").click();
    cy.fillFormCreateOffer({ ...offer, internalOrder: true });
    cy.fillFormCreateParameter(parameter);
    cy.get("[data-e2e='create-offer-btn']").click();
    cy.get("[data-e2e='offer']").should("have.length", 4);
    cy.get("[data-e2e='offer'] .badge-right").eq(3).should("include.text", "Order required");

    cy.get("[data-e2e='publish-btn']").click();
    cy.get(".service-details-header h2")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='query-submit-btn']").click();
        cy.get("[data-e2e='service-name']").should("include.text", value);
        cy.contains("[data-e2e='service-name']", value).click();
        cy.get("[data-e2e='access-service-btn']").should("be.visible");
        cy.get("[data-e2e='select-offer-btn']").eq(1).click();
        cy.contains("a", "Go to the order website");
        cy.contains("a", "Configuration").should("not.exist");
        cy.go("back");
        cy.get("[data-e2e='select-offer-btn']").eq(2).click();
        cy.contains("a", "Go to the service").should("be.visible");
        cy.contains("a", "Configuration").should("not.exist");
        cy.go("back");
        cy.get("[data-e2e='select-offer-btn']").eq(3).click();
        cy.contains("p", "ordered via EOSC Marketplace").should("be.visible");
        cy.contains("a", "Configuration").should("be.visible");
      });
  });

  it("should go to Resources in Backoffice and edit one of service", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource, correctLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.contains("a", "Edit").click();
    cy.fillFormCreateResource({ basicName: "Edited service" }, correctLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.contains(".alert-success", message.successUpdationMessage).should("be.visible");
    cy.contains("h2", "Edited service").should("be.visible");
  });

  it("should go to Preview mode, back to edit and create service", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource4, correctLogo);
    cy.get("[data-e2e='preview-btn']").click();
    cy.contains("div", "Service preview").should("be.visible");
    cy.get("[data-e2e='go-back-edit-btn']").click();
    cy.get("[data-e2e='submit-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.contains("a", "Edit service").should("be.visible");
    cy.contains("a", "Set parameters and offers").should("be.visible");
  });

  it("should go to Preview mode and confirm changes", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource5, correctLogo);
    cy.get("[data-e2e='preview-btn']").click();
    cy.contains("div", "Service preview").should("be.visible");
    cy.get("[data-e2e='confirm-changes-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.contains("a", "Edit service").should("be.visible");
    cy.contains("a", "Set parameters and offers").should("be.visible");
  });

  it("shouldn't go to Preview mode with wrong data format", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(
      { ...resource, basicWebpage_url: "wrongFormat", contactEmail: "wrongFormat" },
      correctLogo,
    );
    cy.get("[data-e2e='preview-btn']").click();
    cy.contains("div.invalid-feedback", message.alertEmailValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertUrlValidation).should("be.visible");
  });

  it("shouldn't go to Preview mode with wrong logo", () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resource6, wrongLogo);
    cy.get("[data-e2e='preview-btn']").click();
    cy.contains("div.invalid-feedback", message.alertLogoValidationPreview).should("be.visible");
  });

  it("should go to Backoffice and create service by filling in all fields", { tags: "@extended-test" }, () => {
    cy.visit("/backoffice/services/new");
    cy.fillFormCreateResource(resourceExtented, correctLogo);
    cy.get("[data-e2e='submit-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.contains("a", "Edit service").should("be.visible");
    cy.contains("a", "Set parameters and offers").should("be.visible");
    cy.contains("span", "unpublished").should("be.visible");
    cy.get("[data-e2e='publish-btn']").click();
    cy.contains("span", "published").should("be.visible");
    cy.get(".service-details-header h2")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='query-submit-btn']").click();
        cy.get("[data-e2e='service-name']").should("include.text", value);
        cy.contains("[data-e2e='service-name']", value).click();
        cy.get("[data-e2e='access-service-btn']").should("be.visible");
        cy.get("[data-e2e='service-details-btn']").click();
        cy.hasResourceDetails();
        cy.intercept("/services/*").as("servicesPage");
        cy.get("[data-e2e='service-about-btn']").click();
        cy.hasResourceAbout();
        cy.wait("@servicesPage");
        cy.get("[data-e2e='tag-btn']").click();
        cy.location("href").should("contain", "/services?tag=");
        cy.get("[data-e2e='filter-tag']").should("be.visible");
      });
  });
});
