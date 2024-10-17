describe("Scientific domain", () => {
  beforeEach(() => {
    cy.visit("/");
  });

  it.skip("should go to services page with selected scientific domain", () => {
    cy.intercept("GET", "/services*").as("services");
    cy.get("a[data-e2e='branch-link']").eq(0).click();
    cy.location("href").should("include", "search/service");
  });
  it.skip("should go to services page with selected categories", () => {
    cy.intercept("GET", "/categories/*").as("categories");
    cy.get("li").contains("Categories").click();
    cy.get("a[href*='categories'][data-e2e='branch-link']").eq(0).click();
    cy.location("href").should("include", "search");
  });
});
