describe("Filter decidated for", () => {
  beforeEach(() => {
    cy.visit("/services");
  });
  
  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']")
      .should("not.exist")
    cy.get("#collapse_target_users [data-e2e='filter-checkbox']")
      .eq(0)
      .click();
    cy.location("href")
      .should("include", "/services?target_users");
    cy.get("[data-e2e='filter-tag']")
      .should("be.visible")
  });
});
