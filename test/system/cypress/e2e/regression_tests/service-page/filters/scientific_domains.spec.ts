describe("Filter scientific domains", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#scientific_domains-filter").click();
    cy.get("#collapse_scientific_domains [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should("include", "/services?scientific_domains");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
