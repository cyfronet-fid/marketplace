describe("Target user", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it.skip("should go to service page with selected filter", () => {
    cy.get("a[href*='dedicated_for'][data-e2e='communities_target-user']").eq(0).click();
    cy.location("href").should("include", "/services?dedicated_for");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
  it.skip("should go to page with all target user", () => {
    cy.get("a[href*='/target_users'][data-e2e='more-link-communities_target-users']").click();
    cy.location("href").should("eq", Cypress.config().baseUrl + "/target_users");
    cy.get("[data-e2e='target_user-list']").contains("Target Users").should("be.visible");
  });
});
