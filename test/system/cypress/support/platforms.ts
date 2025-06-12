/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IPlatform } from "../factories/platform.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreatePlatform(platform: Partial<IPlatform>): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("fillFormCreatePlatform", (platform: IPlatform) => {
  if (platform.name) {
    cy.get("#platform_name").clear({ force: true }).type(platform.name);
  }
});
