import { UserFactory} from "../../../../factories/user.factory";
describe("Favourites", () => {
const user = UserFactory.create();

  beforeEach(() => {
    cy.visit("/services");
    cy.intercept("POST", "/favourites/services").as("addToFavourites");
  })

  it.skip("should add and delete service from favourites - login user", () => {
    cy.loginAs(user);
    cy.get("[data-e2e='my-eosc-button']")
      .click();
    cy.get("[data-e2e='favourites']")
       .click();
    cy.contains("You have no favourite resources yet.")
      .should("be.visible");
    cy.get("[data-e2e='go-to-resources-button']")
     .click();
    cy.location("href")
      .should("include", "/services");
    cy.get("[data-e2e='favourite-checkbox']")
      .eq(0)
      .click();
    cy.wait("@addToFavourites")
      .its('response.statusCode')
      .should('eq', 200);
    cy.get("[data-e2e='favourites-popup']")
      .should("be.visible");
    cy.get("[data-e2e='favourites-popup-button-ok']")
      .click();

    cy.get("[data-e2e='my-eosc-button']")
      .click();
    cy.get("[data-e2e='favourites']")
      .click();
    cy.get("[data-e2e='favourite-result']")
      .should("be.visible")
      .and("have.length", 1);

    cy.get("[data-e2e='favourite-checkbox']")
      .click();
    cy.contains("You have no favourite resources yet.")
      .should("be.visible");
  });

  
  it("shouldn't remove service from favourites", () => {
    cy.loginAs(user)
    cy.get("[data-e2e='favourite-checkbox']")
      .eq(0)
      .click();
    cy.wait("@addToFavourites")
      .its('response.statusCode')
      .should('eq', 200);
    cy.get("[data-e2e='favourites-popup']")
      .should("be.visible");
    cy.logout();
    cy.get("[data-e2e='favourite-checkbox']")
      .eq(0)
      .click();
    cy.wait("@addToFavourites")
      .its('response.statusCode')
      .should('eq', 200);

    cy.get("[data-e2e='favourites-popup-button-ok']")
      .click();
    
    cy.get("[data-e2e='favourite-checkbox']")
      .eq(0)
      .click();
    cy.wait("@addToFavourites")
      .its('response.statusCode')
      .should('eq', 204);

    cy.loginAs(user)

    cy.request({
          url: "/favourites",
      }).its('body').then(html=>{
      const $favouriteElement = Cypress.$(html).find('[data-e2e="favourite-result"]')
      expect($favouriteElement)
          .to.have.property('length')
          .equal(1)
      })
  });
});
