import { UserFactory } from "../../../../factories/user.factory";
describe("My profile", () => {
  const user = UserFactory.create();

  beforeEach(() => {
    cy.visit("/services");
    cy.loginAs(user);
  });

  it("should add and remove Additional information", () => {
    cy.visit("/profile");
    cy.location("href").should("contain", "/profile");
    cy.get("[data-e2e='additional-inf-edit']").click();
    cy.get("[data-e2e='categories-select']")
      .parent()
      .click()
      .then(($el) => {
        cy.wrap($el).next().find(".choices__item").eq(1).click();
        cy.wrap($el).next().find(".choices__item").eq(2).click();
      });
    cy.get("body").type("{esc}");
    cy.get("[data-e2e='scientific-domain-select']")
      .parent()
      .click()
      .then(($el) => {
        cy.wrap($el).next().find(".choices__item").eq(1).click();
      });
    cy.get("body").type("{esc}");
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("[data-e2e='category-item'] li").should("have.length", 2);
    cy.get("[data-e2e='scientific-domain-item'] li").should("have.length", 1);

    cy.get("[data-e2e='additional-inf-edit']").click();
    cy.get(".user_scientific_domains .choices__button").contains("Remove item").click();
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("[data-e2e='scientific-domain-item'] li").should("have.length", 0);

    cy.get("[data-e2e='additional-inf-edit']").click();
    cy.get("[data-e2e='delete-btn']").click();
    cy.get("[data-e2e='category-item'] li").should("have.length", 0);
    cy.get("[data-e2e='scientific-domain-item'] li").should("have.length", 0);
  });

  it("should add and remove Email notifications", () => {
    cy.visit("/profile");
    cy.get("[data-e2e='email-notif-edit']").click();
    cy.get("#user_categories_updates").click();
    cy.get("#user_scientific_domains_updates").click();
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("[data-e2e='email-notif-item'] li").should("have.length", 2);

    cy.get("[data-e2e='email-notif-edit']").click();
    cy.get("#user_categories_updates").click();
    cy.get("[data-e2e='submit-btn']").click();
    cy.get("[data-e2e='email-notif-item'] li").should("have.length", 1);

    cy.get("[data-e2e='email-notif-edit']").click();
    cy.get("[data-e2e='delete-btn']").click();
    cy.get("[data-e2e='email-notif-item'] li").should("have.length", 0);
  });
});
