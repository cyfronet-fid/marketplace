import { providerJson } from "../fixtures/provider_playload"

/**
 * Define new commands types for typescript (for autocompletion)
 */
 import { IProviders, IProvidersExtended } from "../factories/provider.factory";

declare global {
  namespace Cypress {
    interface Chainable {

      checkVisibilityOfProviderInMarketplace(name: string): Cypress.Chainable<void>;

      checkInvisibilityOfProviderInMarketplace(name: string): Cypress.Chainable<void>;

      checkVisibilityOfDetails():Cypress.Chainable<void>;

      checkVisibilityOfAbout():Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("checkVisibilityOfProviderInMarketplace", (provider: string) => {
  cy.get("[data-e2e='searchbar-input']").
    type(provider, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Provider")
    .should("be.visible");
  cy.get("a[data-e2e='more-link-providers']")
    .click();
  cy.contains("a", provider)
    .should("be.visible")
    .click();
  cy.contains("a", "Browse resources")
    .should("be.visible");
});

Cypress.Commands.add("checkInvisibilityOfProviderInMarketplace", (provider: string) => {
  cy.get("a[data-e2e='more-link-providers']")
    .click();
  cy.contains("a", provider)
    .should("not.exist");
  cy.get("[data-e2e='searchbar-input']").
    type(provider, { force: true });
  cy.contains("[data-e2e='autocomplete-results'] li", "Provider")
    .should("not.exist");
});

Cypress.Commands.add("checkVisibilityOfDetails", () => {
  const providerDetails = [
   "Classification",
   "Tags",
   providerJson.tags[0],
   "ESFRI Type",
   "Landmark",
   "ESFRI Domain",
   "Physical Sciences & Engineering",
   "MERIL Scientific Categorisation",
   "Other: Other",
   "Networks",
   "World Data System (WDS)",
   "Areas of Activity",
   "Applied Research",
   "Affiliations",
   providerJson.affiliations[0],
   "Certifications",
   providerJson.certifications[0],
   "Hosting Legal Entity",
   "EUDAT",
   "Structure Types",
   "Virtual",
   "Societal Grand Challenges",
   "Environment",
   "National Roadmaps",
   providerJson.nationalRoadmaps[0]
  ]

  for (const value of providerDetails) {
   cy.contains(value).should("be.visible")
 }
});

Cypress.Commands.add("checkVisibilityOfAbout", () => {
  const providerAbout = [
    providerJson.description,
   "Provider coverage",
   "Classification",
   "Humanities",
   "Other Humanities",
   "Multimedia",
   providerJson.multimedia[0].multimediaName,
   "Address",
   "Contact",
   providerJson.tags,
   providerJson.location.streetNameAndNumber,
   providerJson.location.postalCode,
   providerJson.location.city,
   providerJson.location.region,
   providerJson.location.country,
   providerJson.publicContacts.firstName,
   providerJson.publicContacts.lastName,
   providerJson.publicContacts.email,
   providerJson.publicContacts.phone,
  ]
})