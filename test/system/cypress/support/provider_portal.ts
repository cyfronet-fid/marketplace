import { providerJson } from "../fixtures/provider_playload";
import { resourceJson } from "../fixtures/resource_playload";

/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IProviders, IProvidersExtended } from "../factories/provider.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      checkVisibilityOfProviderInMarketplace(name: string): Cypress.Chainable<void>;

      checkInvisibilityOfProviderInMarketplace(name: string): Cypress.Chainable<void>;

      checkVisibilityOfProviderDetails(): Cypress.Chainable<void>;

      checkVisibilityOfProviderAbout(): Cypress.Chainable<void>;

      checkVisibilityOfResourceInMarketplace(name: string): Cypress.Chainable<void>;

      checkInvisibilityOfResourceInMarketplace(name: string): Cypress.Chainable<void>;

      checkVisibilityOfResourceDetails(): Cypress.Chainable<void>;

      checkVisibilityOfResourceAbout(): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("checkVisibilityOfProviderInMarketplace", (provider: string) => {
  cy.wait(50000);
  cy.get("[data-e2e='searchbar-input']").type(provider, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Provider").should("be.visible");
  cy.get("a[data-e2e='more-link-providers']").click();
  cy.contains("a", provider).should("be.visible").click();
  cy.contains("a", "Browse resources").should("be.visible");
});

Cypress.Commands.add("checkInvisibilityOfProviderInMarketplace", (provider: string) => {
  cy.wait(50000);
  cy.get("a[data-e2e='more-link-providers']").click();
  cy.contains("a", provider).should("not.exist");
  cy.get("[data-e2e='searchbar-input']").type(provider, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Provider").should("not.exist");
});

Cypress.Commands.add("checkVisibilityOfProviderDetails", () => {
  const providerDetails = [
    "Provider coverage",
    "Hosting Legal Entity",
    "Legal Status",
    "Public contacts",
    providerJson.publicContacts[0].email,
  ];

  for (const value of providerDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("checkVisibilityOfProviderAbout", () => {
  const providerAbout = [
    providerJson.description,
    "Provider coverage",
    "Germany",
    "Public contacts",
    providerJson.publicContacts[0].email,
  ];

  for (const value of providerAbout) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("checkVisibilityOfResourceInMarketplace", (resource: string) => {
  cy.wait(50000);
  cy.get("[data-e2e='searchbar-input']").type(resource, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Services").should("be.visible");
  cy.get("[data-e2e='query-submit-btn']").click();
  cy.contains("[data-e2e='service-name']", resource).click();
  cy.get("[data-e2e='access-service-btn']").should("be.visible");
});

Cypress.Commands.add("checkInvisibilityOfResourceInMarketplace", (resource: string) => {
  cy.wait(50000);
  cy.get("[data-e2e='searchbar-input']").type(resource, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Services").should("not.exist");
});

Cypress.Commands.add("checkVisibilityOfResourceAbout", () => {
  const resourceDetails = ["Humanities", "Arts", "Compute", "Orchestration"];

  cy.contains(resourceJson.description).should("be.visible");
  for (const value of resourceDetails) {
    cy.contains("li", value).should("be.visible");
  }
});

Cypress.Commands.add("checkVisibilityOfResourceDetails", () => {
  const resourceAbout = [
    "Classification",
    "Access Types",
    "Mail-In",
    "Tags",
    resourceJson.tags[0],
    "Marketing",
    "Order",
    "Order type",
    "Fully Open Access",
    "Order url",
    "Public Contacts",
    resourceJson.publicContacts[0].email,
    "Trl",
    "1 - BASIC PRINCIPLES OBSERVED",
    "Management",
    "Terms of use",
    "Privacy policy",
    "Access policies",
  ];

  for (const value of resourceAbout) {
    cy.contains(value).should("be.visible");
  }
});
