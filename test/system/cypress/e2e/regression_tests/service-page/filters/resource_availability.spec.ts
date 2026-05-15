describe("Removed resource availability filter", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("is not visible in the V6 service search", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#geographical_availabilities-filter").should("not.exist");
  });
});
