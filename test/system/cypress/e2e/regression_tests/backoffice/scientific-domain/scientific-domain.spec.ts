import { ScientificDomainFactory } from "cypress/factories/scientific-domain.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { ScientificDomainMessages } from "../../../../fixtures/messages";

describe("Scientific Domain", () => {
  const user = UserFactory.create({ roles: ["service_portfolio_manager"] });
  const [scientificDomain, scientificDomain2, scientificDomain3, scientificDomain4, scientificDomain5] = [
    ...Array(5),
  ].map(() => ScientificDomainFactory.create());
  const message = ScientificDomainMessages;

  const correctLogo = "logo.jpg";
  const wrongLogo = "logo.svg";

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  it.skip("should create new scientific domain without parent", () => {
    cy.openUserDropdown();
    cy.get("[data-e2e='backoffice']").click();
    cy.location("href").should("contain", "/backoffice");
    cy.get("[data-e2e='other_settings']").click();
    cy.location("href").should("contain", "backoffice/other_settings");
    cy.get("[data-e2e='scientific-domains']").click();
    cy.location("href").should("contain", "backoffice/other_settings/scientific_domains");
    cy.get("[data-e2e='add-new-scientific-domain']").click();
    cy.fillFormCreateScientificDomain(scientificDomain, correctLogo);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.contains(".alert-success", message.successCreationMessage).should("be.visible");
    cy.location("href").should("contain", `/backoffice/other_settings/scientific_domains/`);
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[data-e2e='branch-link']").contains(value).click();
        cy.location("href").should("contain", `search/service`);
      });
  });

  it("should create new scientific domain with parent", () => {
    cy.visit("/backoffice/other_settings/scientific_domains/new");
    cy.fillFormCreateScientificDomain({ ...scientificDomain2, parent: "Natural Sciences" }, correctLogo);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.location("href").should("not.contain", "new");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/services");
        cy.get("#scientific_domains-filter").click();
        cy.get("#collapse_scientific_domains [data-e2e='filter-checkbox']")
          .next()
          .contains("Natural Sciences")
          .parent()
          .next()
          .next()
          .contains(value)
          .click();
        cy.get("[data-e2e='filter-tag']").should("be.visible").and("contain", value);
      });
  });

  it.skip("should add new scientific domain without logo", () => {
    cy.visit("/backoffice/other_settings/scientific_domains/new");
    cy.fillFormCreateScientificDomain(scientificDomain3, false);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.location("href").should("contain", `/backoffice/scientific_domains/`);
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[data-e2e='branch-link']").contains(value).click();
        cy.location("href").should("contain", `search/service`);
      });
  });

  it("shouldn't create new scientific domain", () => {
    cy.visit("/backoffice/other_settings/scientific_domains/new");
    cy.fillFormCreateScientificDomain({ ...scientificDomain4, name: "" }, wrongLogo);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.contains("div.invalid-feedback", message.alertLogoValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertNameValidation).should("be.visible");
  });

  it("shouldn't delete scientific domain with successors connected to it", () => {
    cy.visit("/backoffice/other_settings/scientific_domains");
    cy.get("[data-e2e='backoffice-scientific-domains-list'] li").eq(0).find("a.delete-icon").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains(".alert-danger", message.alertDeletionMessageSuccessors).should("be.visible");
  });

  it("shouldn't delete scientific domain with services connected to it", () => {
    cy.visit("/backoffice/other_settings/scientific_domains");
    cy.get("[data-e2e='backoffice-scientific-domains-list'] li")
      .contains("Biological Sciences")
      .parent()
      .find("a.delete-icon")
      .click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains(".alert-danger", message.alertDeletionMessageResource).should("be.visible");
  });

  it("should delete scientific domain without services", () => {
    cy.visit("/backoffice/other_settings/scientific_domains/new");
    cy.fillFormCreateScientificDomain(scientificDomain5, correctLogo);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.location("pathname").should("not.contain", "new");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/backoffice/other_settings/scientific_domains");
        cy.contains(value).parent().find("a.delete-icon").click();
        cy.get("[data-e2e='confirm-accept']").click();
        cy.contains(".alert-success", message.successDeletionMessage).should("be.visible");
      });
  });

  it("should edit scientific domain", () => {
    cy.visit("/backoffice/other_settings/scientific_domains");
    cy.get("[data-e2e='backoffice-scientific-domains-list'] li").eq(0).find("a").contains("Edit").click();
    cy.fillFormCreateScientificDomain({ ...scientificDomain, name: "Edited category" }, false);
    cy.get("[data-e2e='create-scientific-domain-btn']").click();
    cy.contains(".alert-success", message.successUpdationMessage).should("be.visible");
  });
});
