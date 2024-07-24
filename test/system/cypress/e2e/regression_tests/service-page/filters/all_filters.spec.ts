describe("All filters", () => {
  beforeEach(() => {
    cy.visit("/services");
  });

  it("should select filter and enter phrase in main searchbar", () => {
    cy.location("pathname").should("eq", "/services");
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.get("#dedicated_for-filter").click();
    cy.get("#collapse_dedicated_for [data-e2e='filter-checkbox']").eq(0).click();
    cy.get("#related_platforms-filter").click();
    cy.get("#collapse_related_platforms [data-e2e='filter-checkbox']").eq(0).click();
    cy.get("#providers-filter").click();
    cy.get("#collapse_providers [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should("match", /(?=.*dedicated_for)(?=.*related_platforms)(?=.*providers)/);
    cy.get("[data-e2e='filter-tag']").should("be.visible").and("have.length", 3);
    cy.get("[data-e2e='select-order'] > option")
      .eq(1)
      .invoke("text")
      .then((value) => {
        cy.get("[data-e2e='select-order']").select(value);
      });
    cy.location("href").should(
      "match",
      /(?=.*dedicated_for)(?=.*related_platforms)(?=.*providers)(?=.*sort=-sort_name)/,
    );
    cy.get("[data-e2e='searchbar-input']").type("EGI").type("{enter}");
    cy.location("href").should(
      "match",
      /(?=.*related_platforms)(?=.*dedicated_for)(?=.*providers)(?=.*q=EGI)(?=.*sort=_score)/,
    );
    cy.get("[data-e2e='filter-tag']").should("be.visible").and("have.length", 3);
    cy.get("#scientific_domains-filter").click();
    cy.get("#collapse_scientific_domains [data-e2e='filter-checkbox']").eq(0).click();
    cy.location("href").should(
      "match",
      /(?=.*related_platforms)(?=.*dedicated_for)(?=.*providers)(?=.*q=EGI)(?=.*sort=_score)(?=.*scientific_domains)/,
    );
    cy.get("[data-e2e='filter-tag']").should("be.visible").and("have.length", 5);
    cy.get("[data-e2e='filter-tag'] a").eq(0).click();
    cy.get("[data-e2e='filter-tag']").should("be.visible").and("have.length", 3);
    cy.location("href").should(
      "match",
      /(?=.*related_platforms)(?=.*dedicated_for)(?=.*providers)(?=.*q=EGI)(?=.*sort=_score)/,
    );
    cy.get("span").contains("Clear all filters").click();
    cy.get("[data-e2e='filter-tag']").should("not.exist");
    cy.location("href").should("match", /(?=.q=EGI)(?=.*sort=_score)/);
    cy.get("[data-e2e='search-clear-btn']").click();
    cy.location("pathname").should("eq", "/services");
  });
});
