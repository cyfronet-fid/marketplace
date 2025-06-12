describe("Filter resource availabilities", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter", () => {
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#geographical_availabilities-filter").click();
    cy.get("#collapse_geographical_availabilities [data-e2e='filter-select'] > option")
      .eq(1)
      .invoke("text")
      .then((value) => {
        cy.get("#collapse_geographical_availabilities [data-e2e='filter-select']").select(value);
      });
    cy.location("href").should("include", "/services?geographical_availabilities");
    cy.get("[data-e2e='filter-tag']").should("be.visible");
  });
});
