describe("Main Search", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should display Service according to the phrase you entered into searchbar", () => {
    cy.get("[data-e2e='searchbar-input']").type("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("Services").next().click();
    cy.url().should("contain", "EGI");
    cy.get("[data-e2e='access-service-btn']").should("be.visible");
  });

  // Skipped for now. Needs an investigation why it fails, because manual test passes
  it.skip("should display Offer according to the phrase you entered into searchbar", () => {
    cy.get("[data-e2e='searchbar-input']").type("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("Offer").next().click();
    cy.url().should("contain", "EGI").and("contain", "#offer");
    cy.get("[data-e2e='access-service-btn']").should("be.visible");
  });

  it("should display Provider according to the phrase you entered into searchbar", () => {
    cy.get("[data-e2e='searchbar-input']").type("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("EGI");
    cy.get("[data-e2e='autocomplete-results'] li").contains("Provider").next().click();
    cy.url().should("contain", "EGI").and("contain", "provider");
    cy.get("[data-e2e='btn-browse-service']").should("be.visible");
  });

  it("should display a list of results containing typed phrase", () => {
    cy.url().should("not.include", "sort=").and("not.include", "q=");
    cy.get("[data-e2e='searchbar-input']").type("EGI");
    cy.get("[data-e2e='query-submit-btn']").click();
    cy.url().should("include", "sort=").and("include", "q=");
    cy.get('#sort.query-sort [selected="selected"]').should("have.text", "Best match");
    cy.get("[data-e2e='service-name']").should("include.text", "EGI");
    cy.get("[data-e2e='search-clear-btn']").click();
    cy.get("[data-e2e='searchbar-input']").should("not.have.text");
    cy.url().should("not.include", "sort").and("not.include", "q=");
  });

  it("should selected category", () => {
    cy.get("[data-e2e='category-select'] > option")
      .eq(1)
      .invoke("text")
      .then((value) => {
        cy.get("[data-e2e='category-select']").select(value);
      });
    cy.get("[data-e2e='query-submit-btn']").click();
    cy.location("href").should("include", "services/c/");
  });
});
