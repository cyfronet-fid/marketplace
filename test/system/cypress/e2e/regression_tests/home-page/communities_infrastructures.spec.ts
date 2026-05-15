describe("Communities and infrastructures", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it("does not expose the removed related_platforms service filter", () => {
    cy.get("a[href*='related_platforms'][data-e2e='communities_target-user']").should("not.exist");
  });
  it.skip("should go to page with all communities/infrastructures", () => {
    cy.get("a[href*='/communities'][data-e2e='more-link-communities_target-users']").click();
    cy.location("href").should("eq", Cypress.config().baseUrl + "/communities");
    cy.get("[data-e2e='communities-list']").contains("Communities and infrastructures").should("be.visible");
  });
});
