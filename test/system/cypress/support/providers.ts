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

  if (provider.marketingMultimedia) {
    cy.get("#provider_link_multimedia_urls_attributes_0_url").clear().type(provider.marketingMultimedia);
  }

  if (provider.classificationScientificDomains) {
    cy.get("#classification-header").click();
    selectItemsMultipleChoice(provider.classificationScientificDomains, ".provider_scientific_domains");
  }

  if (provider.classificationTag) {
    cy.get("#provider_tag_list").clear().type(provider.classificationTag);
  }

  if (provider.classificationStructureTypes) {
    selectItemsMultipleChoice(provider.classificationStructureTypes, ".provider_structure_types");
  }

  if (provider.locationStreet) {
    cy.get("#location-header").click();
  }

  if (provider.locationStreet) {
    cy.get("#provider_street_name_and_number").clear({ force: true }).type(provider.locationStreet);
  }

  if (provider.locationPostCode) {
    cy.get("#provider_postal_code").clear({ force: true }).type(provider.locationPostCode);
  }

  if (provider.locationCity) {
    cy.get("#provider_city").clear({ force: true }).type(provider.locationCity);
  }

  if (provider.locationRegion) {
    cy.get("#provider_region").clear({ force: true }).type(provider.locationRegion);
  }

  if (provider.locationCountry) {
    cy.get("#provider_country").select(provider.locationCountry);
  }

  if (provider.contactFirstname) {
    cy.get("#contact-header").click();
  }

  if (provider.contactFirstname) {
    cy.get("#provider_main_contact_attributes_first_name").clear({ force: true }).type(provider.contactFirstname);
  }

  if (provider.contactLastname) {
    cy.get("#provider_main_contact_attributes_last_name").clear({ force: true }).type(provider.contactLastname);
  }

  if (provider.contactEmail) {
    cy.get("#provider_main_contact_attributes_email").clear({ force: true }).type(provider.contactEmail);
  }

  if (provider.contactPhone) {
    cy.get("#provider_main_contact_attributes_phone").clear({ force: true }).type(provider.contactPhone);
  }

  if (provider.contactPosition) {
    cy.get("#provider_main_contact_attributes_position").clear({ force: true }).type(provider.contactPosition);
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
    cy.get("#provider_public_contacts_attributes_0_email").clear({ force: true }).type(provider.publicContactsEmail);
  }

  if (provider.publicContactsPhone) {
    cy.get("#provider_public_contacts_attributes_0_phone").clear({ force: true }).type(provider.publicContactsPhone);
  }

  if (provider.publicContactsPosition) {
    cy.get("#provider_public_contacts_attributes_0_position")
      .clear({ force: true })
      .type(provider.publicContactsPosition);
  }

  if (provider.maturityProviderLifeCycleStatus) {
    cy.get("#maturity-header").click();
    selectItemSingleChoice(provider.maturityProviderLifeCycleStatus, ".provider_provider_life_cycle_status");
  }

  if (provider.maturityCertifications) {
    cy.get("#provider_certifications_0").clear({ force: true }).type(provider.maturityCertifications);
  }

  if (provider.dependenciesParticipatingCountries) {
    cy.get("#dependencies-header").click();
    selectItemsMultipleChoice(provider.dependenciesParticipatingCountries, ".provider_participating_countries");
  }

  if (provider.dependenciesAffiliations) {
    cy.get("#provider_affiliations_0").clear({ force: true }).type(provider.dependenciesAffiliations);
  }

  if (provider.dependenciesNetworks) {
    selectItemsMultipleChoice(provider.dependenciesNetworks, ".provider_networks");
  }

  if (provider.otherESFRIDomains) {
    cy.get("#other-header").click();
    selectItemsMultipleChoice(provider.otherESFRIDomains, ".provider_esfri_domains");
  }

  if (provider.otherESFRIType) {
    selectItemSingleChoice(provider.otherESFRIType, ".provider_esfri_type");
  }

  if (provider.otherMerilScientificDomains) {
    selectItemsMultipleChoice(provider.otherMerilScientificDomains, ".provider_meril_scientific_domains");
  }

  if (provider.otherAreasOfActivity) {
    selectItemsMultipleChoice(provider.otherAreasOfActivity, ".provider_areas_of_activity");
  }

  if (provider.otherSocietalGrandChallenges) {
    selectItemsMultipleChoice(provider.otherSocietalGrandChallenges, ".provider_societal_grand_challenges");
  }

  if (provider.otherNationalRoadmaps) {
    cy.get("#provider_national_roadmaps_0").clear({ force: true }).type(provider.otherNationalRoadmaps);
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
  const providerDetails = [
    "Classification",
    "Tags",
    "ESFRI Type",
    "ESFRI Domain",
    "MERIL Scientific Categorisation",
    "Networks",
    "Affiliations",
    "Certifications",
    "Areas of Activity",
    "Hosting Legal Entity",
    "Structure Types",
    "Societal Grand Challenges",
    "National Roadmaps",
  ];

  for (const value of providerDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("hasProviderAbout", () => {
  const providerAbout = ["Classification", "Multimedia", "Address", "Contact"];

  for (const value of providerAbout) {
    cy.contains(value).should("be.visible");
  }
});
