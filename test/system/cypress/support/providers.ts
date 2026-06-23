/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IProviders, IProvidersExtended } from "../factories/provider.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreateProvider(provider: Partial<IProvidersExtended>, logo: any): Cypress.Chainable<void>;

      hasProviderDetails(): Cypress.Chainable<void>;

      hasProviderAbout(): Cypress.Chainable<void>;
    }
  }
}

const selectItemsMultipleChoice = (provider: string[], selector: string) => {
  if (provider) {
    provider.forEach((el) => {
      cy.get(selector).find('.choices__input[type="search"]').click().type(el).type("{enter}");
      cy.get(selector).find(".choices__item.choices__item--selectable").contains(el).should("exist");
    });
  }
  cy.get("body").type("{esc}");
};

const selectItemSingleChoice = (provider: string, selector: string) => {
  if (provider) {
    cy.get(selector).find(".choices__list--single").click();
    cy.get(selector).find('.choices__input[type="search"]').type(provider).type("{enter}");
    cy.get(selector).find(".choices__item.choices__item--selectable").contains(provider).should("exist");
  }
  cy.get("body").type("{esc}");
};

Cypress.Commands.add("fillFormCreateProvider", (provider: IProvidersExtended, logo) => {
  if (provider.basicName) {
    cy.get("#basic-header").click();
  }

  if (provider.basicName) {
    cy.get("#provider_name").clear({ force: true }).type(provider.basicName);
  }

  if (provider.basicAbbreviation) {
    cy.get("#provider_abbreviation").clear({ force: true }).type(provider.basicName);
  }

  if (provider.basicHostingLegalEntity) {
    selectItemSingleChoice(provider.basicHostingLegalEntity, ".provider_hosting_legal_entity");
  }

  if (provider.basicWebpage_url) {
    cy.get("#provider_website").clear({ force: true }).type(provider.basicWebpage_url);
  }

  if (provider.marketingDescription) {
    cy.get("#marketing-header").click();
  }

  if (provider.marketingDescription) {
    cy.get("#provider_description").clear().type(provider.marketingDescription);
  }

  if (logo) {
    cy.get("#provider_logo").attachFile(logo);
  }

  if (provider.locationCountry) {
    cy.get("#location-tab").click();
    cy.get("#provider_country").select(provider.locationCountry);
  }

  if (provider.publicContactsEmail) {
    cy.get("#contacts-tab").click();
    cy.get("#provider_public_contact_emails").clear({ force: true }).type(provider.publicContactsEmail);
  }

  if (provider.adminEmail) {
    cy.get("#admins-header").click();
  }

  if (provider.adminFirstName) {
    cy.get("#provider_data_administrators_attributes_0_first_name")
      .clear({ force: true })
      .type(provider.adminFirstName);
  }

  if (provider.adminLastName) {
    cy.get("#provider_data_administrators_attributes_0_last_name").clear({ force: true }).type(provider.adminLastName);
  }

  if (provider.adminEmail) {
    cy.get("#provider_data_administrators_attributes_0_email").clear({ force: true }).type(provider.adminEmail);
  }
});

Cypress.Commands.add("hasProviderDetails", () => {
  const providerDetails = ["Provider coverage", "Hosting Legal Entity", "Public contacts"];

  for (const value of providerDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("hasProviderAbout", () => {
  const providerAbout = ["Provider coverage", "Public contacts"];

  for (const value of providerAbout) {
    cy.contains(value).should("be.visible");
  }
});
