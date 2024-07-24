describe("Filter rating", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#rating-filter").click();
    cy.get("#collapse_rating [data-e2e='filter-select'] > option")
      .eq(1)
      .invoke("text")
      .then((value) => {
        cy.get("#collapse_rating [data-e2e='filter-select']").select(value);
      });
    cy.location("href").should("include", "/services?rating");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
