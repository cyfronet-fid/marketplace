describe("Communities and infrastructures", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it.skip("should go to service page with selected filter", () => {
    cy.get("a[href*='related_platforms'][data-e2e='communities_target-user']").eq(0).click();
    cy.location("href").should("include", "/services?related_platforms");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
  it.skip("should go to page with all communities/infrastructures", () => {
    cy.get("a[href*='/communities'][data-e2e='more-link-communities_target-users']").click();
    cy.location("href").should("eq", Cypress.config().baseUrl + "/communities");
    cy.get("[data-e2e='communities-list']").contains("Communities and infrastructures").should("be.visible");
  });
});
