/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IProviders, IProvidersExtended } from "../factories/provider.factory";

declare global {
  namespace Cypress {
    interface Chainable {

      fillFormCreateProvider(provider: Partial<IProvidersExtended>, logo: any): Cypress.Chainable<void>;

    }
  }
}

const selectItem = (provider: string[], selector: string) => {
  cy.get(selector).then(($el) => {
    $el
      .find(".choices__item--selectable")
      .find(".choices__button")
      .each((index, $btn) => $btn.click());
  });

  if (provider && provider.length > 0) {
    provider.forEach((el) => {
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

  cy.get("body")
  .type("{esc}");
};

Cypress.Commands.add("fillFormCreateProvider", (provider: IProvidersExtended, logo) => {
  cy.get("#basic-header")
    .click();

  if (provider.basicName) {
    cy.get("#provider_name")
      .clear({ force: true })
      .type(provider.basicName);
  }

  if (provider.basicAbbreviation) {
    cy.get("#provider_abbreviation")
      .clear({ force: true })
      .type(provider.basicName);
  }

  if (provider.basicWebpage_url) {
    cy.get("#provider_website")
      .clear({ force: true })
      .type(provider.basicWebpage_url);
  }

  cy.get("#marketing-header")
    .click();

  if (provider.marketingDescription) {
    cy.get("#provider_description")
      .clear()
      .type(provider.marketingDescription);
  }

  cy.get("#provider_logo")
    .attachFile(logo);

  if (provider.marketingMultimedia) {
    cy.get("#provider_multimedia_0")
      .clear()
      .type(provider.marketingMultimedia);
  }

  cy.get("#classification-header").click();

  if (provider.classificationScientificDomains) {
    selectItem(provider.classificationScientificDomains, ".provider_scientific_domains");
  }

  if (provider.classificationTag) {
    cy.get("#provider_tag_list_0")
      .clear()
      .type(provider.classificationTag);
  }

  cy.get("#location-header")
    .click()

  if (provider.locationStreet) {
    cy.get("#provider_street_name_and_number")
      .clear({ force: true })
      .type(provider.locationStreet);
  }

  if (provider.locationPostCode) {
    cy.get("#provider_postal_code")
      .clear({ force: true })
      .type(provider.locationPostCode);
  }

  if (provider.locationCity) {
    cy.get("#provider_city")
      .clear({ force: true })
      .type(provider.locationCity);
  }

  if (provider.locationRegion) {
    cy.get("#provider_region")
      .clear({ force: true })
      .type(provider.locationRegion);
  }

  if (provider.locationCountry) {
    cy.get("#provider_country")
      .select(provider.locationCountry);
  }

  cy.get("#contact-header")
    .click();

  if (provider.contactFirstname) {
    cy.get("#provider_main_contact_attributes_first_name")
      .clear({ force: true })
      .type(provider.contactFirstname);
  }

  if (provider.contactLastname) {
    cy.get("#provider_main_contact_attributes_last_name")
      .clear({ force: true })
      .type(provider.contactLastname);
  }

  if (provider.contactEmail) {
    cy.get("#provider_main_contact_attributes_email")
      .clear({ force: true })
      .type(provider.contactEmail);
  }

  if (provider.contactPhone) {
    cy.get("#provider_main_contact_attributes_phone")
      .clear({ force: true })
      .type(provider.contactPhone);
  }

  if (provider.contactPosition) {
    cy.get("#provider_main_contact_attributes_position")
      .clear({ force: true })
      .type(provider.contactPosition);
  }

  if (provider.publicContactsFirstName) {
    cy.get("#provider_public_contacts_attributes_0_first_name")
      .clear({ force: true })
      .type(provider.publicContactsFirstName);
  }

  if (provider.publicContactsLastName) {
    cy.get("#provider_public_contacts_attributes_0_last_name")
      .clear({ force: true })
      .type(provider.publicContactsLastName);
  }

  if (provider.publicContactsEmail) {
    cy.get("#provider_public_contacts_attributes_0_email")
      .clear({ force: true })
      .type(provider.publicContactsEmail);
  }

  if (provider.publicContactsPhone) {
    cy.get("#provider_public_contacts_attributes_0_phone")
      .clear({ force: true })
      .type(provider.publicContactsPhone);
  }

  if (provider.publicContactsPosition) {
    cy.get("#provider_public_contacts_attributes_0_position")
      .clear({ force: true })
      .type(provider.publicContactsPosition);
  }

  cy.get("#maturity-header")
    .click();
  
  if (provider.maturityProviderLifeCycleStatus) {
    selectItem(provider.maturityProviderLifeCycleStatus, ".provider_provider_life_cycle_status");
  }
  
  if (provider.maturityCertifications) {
    cy.get("#provider_certifications_0")
      .clear({ force: true })
      .type(provider.maturityCertifications);
  }

  cy.get("#other-header")
    .click();

  if (provider.otherHostingLegalEntity) {
    cy.get("#provider_hosting_legal_entity")
      .clear({ force: true })
      .type(provider.otherHostingLegalEntity);
  }

  if (provider.otherParticipatingCountries) {
    selectItem(provider.otherParticipatingCountries, ".provider_participating_countries");
  }

  if (provider.otherAffiliations) {
    cy.get("#provider_affiliations_0")
      .clear({ force: true })
      .type(provider.otherAffiliations);
  }

  if (provider.otherNetworks) {
    selectItem(provider.otherNetworks, ".provider_networks");
  }

  if (provider.otherStructureTypes) {
    selectItem(provider.otherStructureTypes, ".provider_structure_types");
  }

  if (provider.otherESFRIDomains) {
    selectItem(provider.otherESFRIDomains, ".provider_esfri_domains");
  }

  if (provider.otherESFRIType) {
    selectItem(provider.otherESFRIType, ".provider_esfri_type");
  }

  if (provider.otherMerilScientificDomains) {
    selectItem(provider.otherMerilScientificDomains, ".provider_meril_scientific_domains");
  }

  if (provider.otherAreasOfActivity) {
    selectItem(provider.otherAreasOfActivity, ".provider_areas_of_activity");
  }

  if (provider.otherSocietalGrandChallenges) {
    selectItem(provider.otherSocietalGrandChallenges, ".provider_societal_grand_challenges");
  }

  if (provider.otherNationalRoadmaps) {
    cy.get("#provider_national_roadmaps_0")
      .clear({ force: true })
      .type(provider.otherNationalRoadmaps);
  }

  cy.get("#admins-header")
    .click();

  if (provider.adminFirstName) {
    cy.get("#provider_data_administrators_attributes_0_first_name")
      .clear({ force: true })
      .type(provider.adminFirstName);
  }

  if (provider.adminLastName) {
    cy.get("#provider_data_administrators_attributes_0_last_name")
      .clear({ force: true })
      .type(provider.adminLastName);
  }

  if (provider.adminEmail) {
    cy.get("#provider_data_administrators_attributes_0_email")
      .clear({ force: true })
      .type(provider.adminEmail);
  }
});
