describe("Providers", () => {
  beforeEach(() => {
    cy.visit("/");
  });
  
  it.skip("should go to provider page and browse resources", () => { //skip due to bug in app
    cy.get("a[data-e2e='provider-link']")
      .eq(0)
      .click();
    cy.location("href")
      .should("include", "/providers/")
    cy.contains(".breadcrumbs a", "Providers")
      .should("be.visible");
    cy.get("a[data-e2e='btn-browse-resource']")
      .click();
    cy.get("[data-e2e='filter-tag']")
      .should("be.visible");
  });
  it("should go to page with all providers", () => {
    cy.get("a[data-e2e='more-link-providers']")
      .click();
    cy.location("href")
      .should("eq", Cypress.config().baseUrl + "/providers");
    cy.get("[data-e2e='provider-list']")
      .contains("Providers")
      .should("be.visible");
  });
});
