/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IResources } from "../factories/resource.factory";
import { IOffers } from "../factories/resource.factory";
import { IParameters } from "../factories/resource.factory";

declare global {
  namespace Cypress {
    interface Chainable {
     
      fillFormCreateResource(resource: Partial<IResources>, logo:any): Cypress.Chainable<void>;

      fillFormCreateOffer(offer: Partial<IOffers>):Cypress.Chainable<void>;

      fillFormCreateParameter(parameter: Partial<IParameters>):Cypress.Chainable<void>;

    }
  }
}

const selectItem = (resource: string[], selector: string) => {
  cy.get(selector).then(($el) => {
    $el
      .find(".choices__item--selectable")
      .find(".choices__button")
      .each((index, $btn) => $btn.click());
  });

  if (resource && resource.length > 0) {
    resource.forEach((el) => {
      cy.get(selector)
        .find('.choices__input[type="search"]')
        .type(el)
        .type("{enter}");
      cy.get(selector)
        .find(".choices__item.choices__item--selectable")
        .contains(el)
        .should("exist");
    });
  }
};

Cypress.Commands.add("fillFormCreateResource", (resource: IResources, logo) => {
  cy.get("#basic-header")
    .click();

  if (resource.basicName) {
    cy.get("#service_name")
      .clear({ force: true })
      .type(resource.basicName);
  }

  if (resource.basicResourceOrganisation) {
    cy.get("#service_resource_organisation_id")
      .select(resource.basicResourceOrganisation);
  }

  // Error: Providers is invalid (no logo image)
  //selectItem(resource.basicProviders, ".service_providers");

  if (resource.basicWebpage_url) {
    cy.get("#service_webpage_url")
      .clear({ force: true })
      .type(resource.basicWebpage_url);
  }

  cy.get("#marketing-header")
    .click();

  if (resource.marketingDescription) {
    cy.get("#service_description")
      .clear()
      .type(resource.marketingDescription);
  }

  if (resource.marketingTagline) {
    cy.get("#service_tagline")
      .clear()
      .type(resource.marketingTagline);
  }

  cy.get("#service_logo")
    .attachFile(logo);

  cy.get("#classification-header").click();

  selectItem(resource.classificationScientificDomains,".service_scientific_domains");

  cy.get("body")
    .type("{esc}");

  selectItem(resource.classificationCategories, ".service_categories");

  cy.get("body")
    .type("{esc}");

  selectItem(resource.classificationDedicatedFor, ".service_target_users");

  cy.get("#availability-header")
    .click();

  selectItem(resource.availabilityGeographicalavailabilities,".service_geographical_availabilities");

  cy.get("body")
    .type("{esc}");

  selectItem(resource.availabilityLanguageavailability,".service_language_availability");

  cy.get("body")
    .type("{esc}");

  cy.get("#contact-header")
    .click();

  if (resource.contactsFirstname) {
    cy.get("#service_main_contact_attributes_first_name")
      .clear({ force: true })
      .type(resource.contactsFirstname);
  }

  if (resource.contactsLastname) {
    cy.get("#service_main_contact_attributes_last_name")
      .clear({ force: true })
      .type(resource.contactsLastname);
  }

  if (resource.contactsEmail) {
    cy.get("#service_main_contact_attributes_email")
      .clear({ force: true })
      .type(resource.contactsEmail);
  }

  if (resource.publicContactsEmail) {
    cy.get("#service_public_contacts_attributes_0_email")
      .clear({ force: true })
      .type(resource.publicContactsEmail);
  }

  cy.get("#maturity-header")
    .click();

  selectItem(resource.maturityTrl, ".service_trl");

  cy.get("#order-header")
    .click();

  if (resource.orderOrdertype) {
    cy.get("#service_order_type")
      .select(resource.orderOrdertype);
  }
});

Cypress.Commands.add("fillFormCreateOffer", (offer: IOffers) => {
  if (offer.name) {
    cy.get("#offer_name")
      .clear({ force: true })
      .type(offer.name);
  }

  if (offer.description) {
    cy.get("#offer_description")
      .clear({ force: true })
      .type(offer.description);
  }

  if(offer.internalOrder){
    cy.get("#offer_internal")
      .check();
  }

  if (offer.orderType) {
    cy.get("#offer_order_type")
      .select(offer.orderType)
  }

  if (offer.orderAccessUrl && !offer.internalOrder) {
    cy.get("#offer_order_url")
      .clear({force:true})
      .type(offer.orderAccessUrl)
  }

  if (offer.orderTargetUrl && offer.internalOrder) {
    cy.get('#offer_oms_params_order_target')
      .clear({force:true})
      .type(offer.orderTargetUrl)
  }
});

Cypress.Commands.add("fillFormCreateParameter", (parameter: IParameters) => {
  cy.get(".parameter-list ul li")
    .eq(0)
    .click();

  cy.get("#attributes-list-button")
    .click();
  
  if (parameter.constantName) {
    cy.get("[id^=offer_parameters_attributes_][id$=_name]")
      .clear({force:true})
      .type(parameter.constantName)
  }

  if (parameter.constantHint) {
    cy.get("[id^=offer_parameters_attributes_][id$=_hint]")
      .clear({force:true})
      .type(parameter.constantName)
  }

  if (parameter.constantValue) {
    cy.get("[id^=offer_parameters_attributes_][id$=_value]")
      .clear({force:true})
      .type(parameter.constantName)
  }
  
  if (parameter.constantValueType) {
    cy.get("[id^=offer_parameters_attributes_][id$=_value_type]")
      .select(parameter.constantValueType)
  }
});