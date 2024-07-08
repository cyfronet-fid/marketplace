describe("Providers", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it.skip("should go to provider page and browse resources", () => {
    cy.get("a[data-e2e='provider-link']").eq(0).click();
    cy.location("href").should("include", "/providers");
    cy.get("a[data-e2e='btn-browse-service']").click();
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
  it.skip("should go to page with all providers", () => {
    cy.get("a[data-e2e='more-link-providers']").click();
    cy.location("href").should("eq", Cypress.config().baseUrl + "/providers");
    cy.get("[data-e2e='provider-list']").contains("Providers").should("be.visible");
  });
});
