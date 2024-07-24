describe("Filter decidated for", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#dedicated_for-filter").click();
    cy.get("#collapse_dedicated_for [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should("include", "/services?dedicated_for");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
