import { UserFactory } from "../../../../factories/user.factory";

describe("Api page", () => {
  const user = UserFactory.create();

  it("should go as unlogin user to api page", () => {
    cy.visit("/api_docs");
    cy.contains("h2", "EOSC Marketplace API Documentation").should("be.visible");
    cy.get("[data-e2e='login-btn']").should("be.visible");
  });

  it("should go as login user to api page", () => {
    cy.visit("/api_docs");
    cy.loginAs(user);
    cy.contains("h2", "EOSC Marketplace API Documentation").should("be.visible");
    cy.contains("a", "Regenerate token").should("be.visible");
    cy.contains("a", "Show token").should("be.visible").click();
    cy.contains("a", "Hide token").should("be.visible").click();
  });

  it("should go to offering and ordering swagger page", () => {
    cy.visit("/api_docs");
    cy.get("[data-e2e='offering-api-link']").invoke("removeAttr", "target").click();
    cy.location("href").should("contain", "swagger").and("contain", "Offering");
    cy.visit("/api_docs");
    cy.get("[data-e2e='ordering-api-link']").invoke("removeAttr", "target").click();
    cy.location("href").should("contain", "swagger").and("contain", "Ordering");
  });
});
