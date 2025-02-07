import { PlatformFactory } from "cypress/factories/platform.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { PlatformMessages } from "../../../../fixtures/messages";

describe("Platform", () => {
  const user = UserFactory.create({ roles: ["coordinator"] });
  const [platform] = [...Array(1)].map(() => PlatformFactory.create());
  const message = PlatformMessages;

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  it.skip("should create new platform", () => {
    cy.openUserDropdown();
    cy.get("[data-e2e='backoffice']").click();
    cy.location("href").should("contain", "/backoffice");
    cy.get("[data-e2e='other_settings']").click();
    cy.location("href").should("contain", "backoffice/other_settings");
    cy.get("[data-e2e='platforms']").click();
    cy.location("href").should("contain", "/backoffice/other_settings/platforms");
    cy.get("[data-e2e='add-new-platform-btn']").click();
    cy.location("href").should("contain", "/backoffice/other_settings/platforms/new");
    cy.fillFormCreatePlatform(platform);
    cy.get("[data-e2e='create-platform-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[href*='/communities'][data-e2e='more-link-communities_target-users']").click();
        cy.get(".special-list-item a").contains(value).click();
        cy.location("href").should("include", "/services?related_platforms");
        cy.get("[data-e2e='filter-tag']").should("be.visible");
      });
  });

  it("shouldn't create new platform", () => {
    cy.visit("/backoffice/other_settings/platforms/new");
    cy.get("[data-e2e='create-platform-btn']").click();
    cy.contains("div.invalid-feedback", message.alertNameValidation).should("be.visible");
  });

  it("should edit platform", () => {
    cy.visit("/backoffice/other_settings/platforms/");
    cy.get("[data-e2e='backoffice-platforms-list'] li").eq(0).find("a").contains("Edit").click();
    cy.fillFormCreatePlatform({ ...platform, name: "Edited category" });
    cy.get("[data-e2e='create-platform-btn']").click();
    cy.contains("div.alert-success", message.successUpdationMessage).should("be.visible");
  });

  it("should delete platform", () => {
    cy.visit("/backoffice/other_settings/platforms");
    cy.get("[data-e2e='backoffice-platforms-list'] li").eq(0).find("a.delete-icon").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });
});
