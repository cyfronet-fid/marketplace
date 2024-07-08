/**
 * Define new commands types for typescript (for autocompletion)
 */
import { ICategory } from "../factories/category.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreateCategory(category: Partial<ICategory>, logo: any): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("fillFormCreateCategory", (category: ICategory, logo = true) => {
  if (logo) {
    cy.get("#category_logo").click().attachFile(logo);
  }

  if (category.name) {
    cy.get("#category_name").clear({ force: true }).type(category.name);
  }

  if (category.description) {
    cy.get("#category_description").clear({ force: true }).type(category.description);
  }

  if (category.parent) {
    cy.get("#category_parent_id").select(category.parent);
  }
});
