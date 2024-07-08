/**
 * Define new commands types for typescript (for autocompletion)
 */
export {};

declare global {
  namespace Cypress {
    interface Chainable {
      visitPage(page): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("visitPage", (page) => {
  cy.visit(page, {
    timeout: 50000, // increase total time for the visit to resolve
    onBeforeLoad: function (contentWindow) {
      // contentWindow is the remote page's window object
      expect(typeof contentWindow, "onBeforeLoad window reference").to.equal("object");
    },
    onLoad: function (contentWindow) {
      // contentWindow is the remote page's window object
      expect(typeof contentWindow, "onLoad window reference").to.equal("object");
    },
  });
});
