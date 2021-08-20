describe("Scientific domain", () => {
  beforeEach(() => {
    cy.visit("/")
  });

  it("should service page with selected filter", () => {
    cy.intercept("GET", "/services*").as("services");
    cy.get("a[href*='services'][data-e2e='branch-link']")
          .eq(0)
          .click();
        cy.wait("@services");
        cy.location("href")
          .should("include", "services?scientific_domains");
        cy.get("[data-e2e='filter-tag']")
          .should("be.visible");
  });
  it("should go to services page with selected category", () => {
    cy.intercept("GET", "/categories/*").as("categories");
    cy.get("li")
      .contains("Categories")
      .click();
    cy.get("a[href*='categories'][data-e2e='branch-link']")
          .eq(0)
          .click();
        cy.wait("@categories");
        cy.location("href")
          .should("include", "services/c/");
  });
});