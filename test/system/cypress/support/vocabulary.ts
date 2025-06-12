/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IVocabulary } from "../factories/vocabulary.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreateVocabulary(vocabulary: Partial<IVocabulary>): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("fillFormCreateVocabulary", (vocabulary: IVocabulary) => {
  if (vocabulary.name) {
    cy.get("[id$=_name]").clear({ force: true }).type(vocabulary.name);
  }

  if (vocabulary.description) {
    cy.get("[id$=description]").clear({ force: true }).type(vocabulary.description);
  }

  if (vocabulary.parent) {
    cy.get("[id$=_parent_id]").select(vocabulary.parent);
  }

  if (vocabulary.eid) {
    cy.get("[id$=_eid]").select(vocabulary.eid);
  }
});
