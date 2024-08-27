describe("Comparison", () => {
  beforeEach(() => {
    cy.visit("/services");
    cy.intercept("POST", "/comparisons/services").as("comparison");
    cy.intercept("GET", "/comparisons").as("comparisonTable");
  });

  it("should add and remove services from comparison - services from the catalogue page", () => {
    cy.get("[data-e2e='comparison-checkbox']").eq(0).click();
    cy.wait("@comparison");
    cy.get("[data-e2e='comparison-bar']").should("be.visible");

    cy.get("[data-e2e='comparison-checkbox']").eq(1).click();
    cy.wait("@comparison");
    cy.get("[data-e2e='comparison-checkbox']").eq(2).click();
    cy.wait("@comparison");
    cy.get("[data-e2e='comparison-checkbox']").eq(3).should("have.attr", "disabled");

    cy.get("[data-e2e='compare-btn']").click();
    cy.wait("@comparisonTable");
    cy.location("href").should("include", "/comparisons");

    cy.get("[data-e2e='services-comparison-table']").should("be.visible");
    cy.get("[data-e2e='delete-service-btn'] svg").should("have.length", 3).eq(0).click();

    cy.wait("@comparisonTable");
    cy.get("[data-e2e='add-next-resource-btn']").click();
    cy.location("href").should("include", "/services");

    cy.get("[data-e2e='comparison-clearAll-btn']").click();
    cy.get("[data-e2e='comparison-bar']").should("not.be.visible");
  });

  it("should add and remove services from comparison - services from details page", () => {
    cy.get("[data-e2e='service-name']").eq(0).click();
    cy.get("[data-e2e='service-details-btn']").should("be.visible");

    cy.get("[data-e2e='comparison-checkbox']").click();
    cy.get("[data-e2e='comparison-bar']").should("be.visible");

    cy.go("back");

    cy.get("[data-e2e='service-name']").eq(2).click();
    cy.get("[data-e2e='service-details-btn']").should("be.visible");
    cy.get("[data-e2e='comparison-checkbox']").click();

    cy.get("[data-e2e='compare-btn']").click();
    cy.wait("@comparisonTable");
    cy.location("href").should("include", "/comparisons");
    cy.get("[data-e2e='add-next-resource-btn']").click();
    cy.location("href").should("include", "/services");

    cy.get("[data-e2e='delete-service-btn']").should("have.length", 2).eq(0).click();
    cy.get("[data-e2e='delete-service-btn']").should("have.length", 1).eq(0).click();
    cy.get("[data-e2e='comparison-bar']").should("not.be.visible");
  });

  it("should add and remove services from comparison - toggle comparison via checkbox", () => {
    cy.get("[data-e2e='comparison-checkbox']")
      .next()
      .contains("Compare")
      .eq(0)
      .click()
      .contains("Remove from comparison");
    cy.wait("@comparison");
    cy.get("[data-e2e='comparison-bar']").should("be.visible");

    cy.get("[data-e2e='comparison-checkbox']")
      .next()
      .contains("Remove from comparison")
      .eq(0)
      .click()
      .contains("Compare");
    cy.wait("@comparison");
    cy.get("[data-e2e='comparison-bar']").should("not.be.visible");
  });
});
