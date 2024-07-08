/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IScientificDomain } from "../factories/scientific-domain.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreateScientificDomain(scientificDomain: Partial<IScientificDomain>, logo: any): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("fillFormCreateScientificDomain", (scientificDomain: IScientificDomain, logo = true) => {
  if (logo) {
    cy.get("#scientific_domain_logo").click().attachFile(logo);
  }

  if (scientificDomain.name) {
    cy.get("#scientific_domain_name").clear({ force: true }).type(scientificDomain.name);
  }

  if (scientificDomain.description) {
    cy.get("#scientific_domain_description").clear({ force: true }).type(scientificDomain.description);
  }

  if (scientificDomain.parent) {
    cy.get("#scientific_domain_parent_id").select(scientificDomain.parent);
  }
});
