describe("Filter providers", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#providers-filter").click();
    cy.get("#collapse_providers [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should("include", "/services?providers");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
