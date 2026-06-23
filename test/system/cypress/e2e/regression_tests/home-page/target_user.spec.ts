describe("Target user", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it("does not expose the removed dedicated_for service filter", () => {
    cy.get("a[href*='dedicated_for'][data-e2e='communities_target-user']").should("not.exist");
  });
  it("does not expose the removed target users page link", () => {
    cy.get("a[href*='/target_users'][data-e2e='more-link-communities_target-users']").should("not.exist");
  });
});
