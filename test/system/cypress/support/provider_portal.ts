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
    //"Hosting Legal Entity",
    //"EUDAT",
    "Structure Types",
    "Virtual",
    "Societal Grand Challenges",
    "Environment",
    "National Roadmaps",
    providerJson.nationalRoadmaps[0],
  ];

  for (const value of providerDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("checkVisibilityOfProviderAbout", () => {
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
    providerJson.tags[0],
    providerJson.location.streetNameAndNumber,
    providerJson.location.postalCode,
    providerJson.location.city,
    providerJson.location.region,
    "Germany",
    providerJson.publicContacts[0].firstName,
    providerJson.publicContacts[0].lastName,
    providerJson.publicContacts[0].email,
    providerJson.publicContacts[0].phone,
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
  const resourceDetails = ["Humanities", "Arts", "Compute", "Orchestration", "Businesses", "Abkhazian"];

  cy.contains(resourceJson.description).should("be.visible");
  for (const value of resourceDetails) {
    cy.contains("li", value).should("be.visible");
  }
});

Cypress.Commands.add("checkVisibilityOfResourceDetails", () => {
  const resourceAbout = [
    "Classification",
    "Target Users",
    "Businesses",
    "Access Types",
    "Mail-In",
    "Access Modes",
    "Free",
    "Tags",
    resourceJson.tags[0],
    "Availability and language",
    "Andorra",
    "Geographical Availabilities",
    "Languages",
    "Abkhazian",
    "Marketing",
    resourceJson.multimedia[0].multimediaName,
    resourceJson.useCases[0].useCaseName,
    "Attribution",
    "Funding Bodies",
    "Academy of Finland (AKA)",
    "Funding Programs",
    "Cohesion Fund (CF)",
    "Grant Project Names",
    "Grant Project",
    "Order",
    "Order type",
    "Fully Open Access",
    "Order url",
    "Public Contacts",
    resourceJson.publicContacts[0].email,
    "Maturity Information",
    "Life Cycle Status",
    "Production",
    "Trl",
    "1 - BASIC PRINCIPLES OBSERVED",
    "Certifications",
    resourceJson.certifications[0],
    "Standards",
    resourceJson.standards[0],
    "Open Source Technologies",
    resourceJson.openSourceTechnologies[0],
    "Version",
    resourceJson.version,
    "Last Update",
    "2020-01-01",
    "Management",
    "Helpdesk",
    "Manual",
    "Terms of use",
    "Privacy policy",
    "Access policies",
    "Training information",
    "Status Monitoring",
    "Maintenance",
    "Financial Information",
    "Payment Model",
    "Pricing",
    "Changelog",
    "Changelog Value",
    resourceJson.version,
  ];

  for (const value of resourceAbout) {
    cy.contains(value).should("be.visible");
  }
});
