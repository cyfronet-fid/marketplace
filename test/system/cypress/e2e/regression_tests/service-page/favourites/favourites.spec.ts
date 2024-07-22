import { UserFactory } from "../../../../factories/user.factory";

// favourites has been removed until they are migrated to dashboard
describe.skip("Favourites", () => {
  const user = UserFactory.create();

  beforeEach(() => {
    cy.visit("/services");
    cy.intercept("POST", "/favourites/services").as("addToFavourites");
  });

  it("should add and delete service from favourites - login user", () => {
    cy.loginAs(user);
    cy.openUserDropdown();
    cy.get("[data-e2e='favourites']").click();
    cy.contains("You have no favourite services yet.").should("be.visible");
    cy.get("[data-e2e='go-to-resources-button']").click();
    cy.location("href").should("include", "/services");
    cy.get("[data-e2e='favourite-checkbox']").eq(0).click();
    cy.wait("@addToFavourites");
    cy.get("[data-e2e='favourites-popup']").should("be.visible");
    cy.get("[data-e2e='favourites-popup-button-ok']").click();
    cy.get("#popup-modal").should("not.be.visible");

    cy.visit("/favourites");
    cy.location("href").should("include", "/favourites");
    cy.get("[data-e2e='favourite-result']").should("be.visible").and("have.length", 1);

    cy.get("[data-e2e='favourite-checkbox']").click();
    cy.contains("You have no favourite services yet.").should("be.visible");
  });

  it("should add service to favourites - doesn't login user", () => {
    cy.get("[data-e2e='favourite-checkbox']").eq(0).click();
    cy.wait("@addToFavourites");
    cy.get("[data-e2e='favourites-popup']").should("be.visible");
    cy.get("[data-e2e='favourites-popup-button-ok']").click();
    cy.get("#popup-modal").should("not.be.visible");
  });

  it("should add service to favourites - service presentation page", () => {
    cy.loginAs(user);
    cy.get("[data-e2e='service-name']").eq(0).click();
    cy.get("[data-e2e='access-service-btn']").should("be.visible");
    cy.get("[data-e2e='favourite-checkbox']").click();
    cy.get("[data-e2e='favourites-popup']").should("be.visible");
    cy.get("[data-e2e='favourites-popup-button-ok']").click();
    cy.visit("/favourites");
    cy.location("href").should("include", "/favourites");
    cy.get("[data-e2e='favourite-result']").should("be.visible").and("have.length", 1);
  });
});
