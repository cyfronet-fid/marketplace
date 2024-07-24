describe("Filter order type", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#order_type-filter").click();
    cy.get("#collapse_order_type [data-e2e='filter-select'] > option")
      .eq(1)
      .invoke("text")
      .then((value) => {
        cy.get("#collapse_order_type [data-e2e='filter-select']").select(value);
      });
    cy.location("href").should("include", "/services?order_type");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
