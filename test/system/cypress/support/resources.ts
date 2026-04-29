/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IResourcesExtended } from "../factories/resource.factory";
import { IOffers } from "../factories/resource.factory";
import { IParameters } from "../factories/resource.factory";

declare global {
  namespace Cypress {
    interface Chainable {
      fillFormCreateResource(resource: Partial<IResourcesExtended>, logo: any): Cypress.Chainable<void>;

      fillFormCreateOffer(offer: Partial<IOffers>): Cypress.Chainable<void>;

      fillFormCreateParameter(parameter: Partial<IParameters>): Cypress.Chainable<void>;

      hasResourceDetails(): Cypress.Chainable<void>;

      hasResourceAbout(): Cypress.Chainable<void>;
    }
  }
}

const selectItemsMultipleChoice = (resource: string[], selector: string) => {
  if (resource && resource.length > 0) {
    resource.forEach((el) => {
      cy.get(selector).find('.choices__input[type="search"]').type(el).type("{enter}");
      cy.get(selector).find(".choices__item.choices__item--selectable").contains(el).should("exist");
    });
  }
  cy.get("body").type("{esc}");
};

Cypress.Commands.add("fillFormCreateResource", (resource: IResourcesExtended, logo) => {
  if (resource.basicName) {
    cy.get("#basic-header").click();
  }

  if (resource.basicName) {
    cy.get("#service_name").clear({ force: true }).type(resource.basicName);
  }

  if (resource.basicResourceOrganisation) {
    cy.get("#service_resource_organisation_id").select(resource.basicResourceOrganisation);
  }

  if (resource.basicProviders) {
    selectItemsMultipleChoice(resource.basicProviders, ".service_providers");
  }

  if (resource.basicWebpage_url) {
    cy.get("#service_webpage_url").clear({ force: true }).type(resource.basicWebpage_url);
  }

  if (resource.marketingDescription) {
    cy.get("#marketing-header").click();
  }

  if (resource.marketingDescription) {
    cy.get("#service_description").clear().type(resource.marketingDescription);
  }

  if (logo) {
    cy.get("#service_logo").attachFile(logo);
  }

  if (resource.classificationScientificDomains) {
    cy.get("#classification-header").click();
  }

  if (resource.classificationScientificDomains) {
    selectItemsMultipleChoice(resource.classificationScientificDomains, ".service_scientific_domains");
  }

  if (resource.classificationCategories) {
    selectItemsMultipleChoice(resource.classificationCategories, ".service_categories");
  }

  if (resource.classificationAccessType) {
    selectItemsMultipleChoice(resource.classificationAccessType, ".service_access_types");
  }

  if (resource.classificationTagList) {
    selectItemsMultipleChoice([resource.classificationTagList], ".service_tag_list");
  }

  if (resource.publicContactsEmail) {
    cy.get("#marketing-header").click();
    cy.get("#service_public_contact_emails").clear({ force: true }).type(resource.publicContactsEmail);
  }

  if (resource.managementHeldeskUrl) {
    cy.get("#management-header").click();
  }

  if (resource.managementTermsOfUseUrl) {
    cy.get("#service_terms_of_use_url").clear({ force: true }).type(resource.managementTermsOfUseUrl);
  }

  if (resource.managementPrivacyPolicyUrl) {
    cy.get("#service_privacy_policy_url").clear({ force: true }).type(resource.managementPrivacyPolicyUrl);
  }

  if (resource.managementAccessPoliciesUrl) {
    cy.get("#service_access_policies_url").clear({ force: true }).type(resource.managementAccessPoliciesUrl);
  }

  if (resource.orderOrdertype) {
    cy.get("#order-header").click();
  }

  if (resource.orderOrdertype) {
    cy.get("#service_order_type").select(resource.orderOrdertype);
  }

  if (resource.orderUrl) {
    cy.get("#service_order_url").clear({ force: true }).type(resource.orderUrl);
  }

});

Cypress.Commands.add("fillFormCreateOffer", (offer: IOffers) => {
  if (offer.name) {
    cy.get("#offer_name").clear({ force: true }).type(offer.name);
  }

  if (offer.description) {
    cy.get("#offer_description").clear({ force: true }).type(offer.description);
  }

  if (offer.internalOrder) {
    cy.get("#offer_internal").check();
  }

  if (offer.orderType) {
    cy.get("#offer_order_type").select(offer.orderType);
  }

  if (offer.orderAccessUrl && !offer.internalOrder) {
    cy.get("#offer_order_url").clear({ force: true }).type(offer.orderAccessUrl);
  }

  if (offer.orderTargetUrl && offer.internalOrder) {
    cy.get("#offer_oms_params_order_target").clear({ force: true }).type(offer.orderTargetUrl);
  }
});

Cypress.Commands.add("fillFormCreateParameter", (parameter: IParameters) => {
  cy.get(".parameter-list ul li").eq(0).click();

  cy.get("#attributes-list-button").click();

  if (parameter.constantName) {
    cy.get("[id^=offer_parameters_attributes_][id$=_name]").clear({ force: true }).type(parameter.constantName);
  }

  if (parameter.constantHint) {
    cy.get("[id^=offer_parameters_attributes_][id$=_hint]").clear({ force: true }).type(parameter.constantName);
  }

  if (parameter.constantValue) {
    cy.get("[id^=offer_parameters_attributes_][id$=_value]").clear({ force: true }).type(parameter.constantName);
  }

  if (parameter.constantValueType) {
    cy.get("[id^=offer_parameters_attributes_][id$=_value_type]").select(parameter.constantValueType);
  }
});

Cypress.Commands.add("hasResourceDetails", () => {
  const resourceDetails = [
    "Classification",
    "Access Types",
    "Tags",
    "Marketing",
    "Required Services",
    "Related Services",
    "Order",
    "Order type",
    "Order url",
    "Public Contacts",
    "Terms of use",
    "Privacy policy",
    "Access policies",
  ];

  for (const value of resourceDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("hasResourceAbout", () => {
  const resourceAbout = ["Classification", "Public contacts", "Suggested compatible services"];

  for (const value of resourceAbout) {
    cy.contains(value).should("be.visible");
  }
});
