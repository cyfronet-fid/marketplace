describe("Filter related infrastructures and platforms", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#related_platforms-filter").click();
    cy.get("#collapse_related_platforms [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should("include", "/services?related_platforms");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
