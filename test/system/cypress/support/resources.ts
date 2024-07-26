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

  if (resource.marketingTagline) {
    cy.get("#service_tagline").clear().type(resource.marketingTagline);
  }

  if (logo) {
    cy.get("#service_logo").attachFile(logo);
  }

  if (resource.marketingMultimedia) {
    cy.get("#service_link_multimedia_urls_attributes_0_url").clear().type(resource.marketingMultimedia);
  }

  if (resource.marketingUseCasesUrl) {
    cy.get("#service_link_use_cases_urls_attributes_0_url").clear().type(resource.marketingUseCasesUrl);
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

  if (resource.classificationDedicatedFor) {
    selectItemsMultipleChoice(resource.classificationDedicatedFor, ".service_target_users");
  }

  if (resource.classificationAccessType) {
    selectItemsMultipleChoice(resource.classificationAccessType, ".service_access_types");
  }

  if (resource.classificationAccessMode) {
    selectItemsMultipleChoice(resource.classificationAccessMode, ".service_access_modes");
  }

  if (resource.classificationTagList) {
    selectItemsMultipleChoice(resource.classificationAccessMode, ".service_tag_list");
  }

  if (resource.availabilityGeographicalAvailabilities) {
    cy.get("#availability-header").click();
  }

  if (resource.availabilityGeographicalAvailabilities) {
    selectItemsMultipleChoice(resource.availabilityGeographicalAvailabilities, ".service_geographical_availabilities");
  }

  if (resource.availabilityLanguageAvailability) {
    selectItemsMultipleChoice(resource.availabilityLanguageAvailability, ".service_language_availability");
  }

  if (resource.locationResourceGeographicLocation) {
    cy.get("#location-header").click();
  }

  if (resource.locationResourceGeographicLocation) {
    selectItemsMultipleChoice(resource.locationResourceGeographicLocation, ".service_resource_geographic_locations");
  }

  if (resource.contactFirstname) {
    cy.get("#contact-header").click();
  }

  if (resource.contactFirstname) {
    cy.get("#service_main_contact_attributes_first_name").clear({ force: true }).type(resource.contactFirstname);
  }

  if (resource.contactLastname) {
    cy.get("#service_main_contact_attributes_last_name").clear({ force: true }).type(resource.contactLastname);
  }

  if (resource.contactEmail) {
    cy.get("#service_main_contact_attributes_email").clear({ force: true }).type(resource.contactEmail);
  }

  if (resource.contactPhone) {
    cy.get("#service_main_contact_attributes_phone").clear({ force: true }).type(resource.contactPhone);
  }

  if (resource.contactOrganistation) {
    cy.get("#service_public_contacts_attributes_0_first_name")
      .clear({ force: true })
      .type(resource.contactOrganistation);
  }

  if (resource.publicContactsFirstName) {
    cy.get("#service_public_contacts_attributes_0_last_name")
      .clear({ force: true })
      .type(resource.publicContactsFirstName);
  }

  if (resource.publicContactsLastName) {
    cy.get("#service_public_contacts_attributes_0_email").clear({ force: true }).type(resource.publicContactsLastName);
  }

  if (resource.publicContactsEmail) {
    cy.get("#service_public_contacts_attributes_0_email").clear({ force: true }).type(resource.publicContactsEmail);
  }

  if (resource.publicContactsPhone) {
    cy.get("#service_public_contacts_attributes_0_phone").clear({ force: true }).type(resource.publicContactsPhone);
  }

  if (resource.publicContactsOrganisation) {
    cy.get("#service_public_contacts_attributes_0_organisation")
      .clear({ force: true })
      .type(resource.publicContactsOrganisation);
  }

  if (resource.publicContactsPosition) {
    cy.get("#service_public_contacts_attributes_0_position")
      .clear({ force: true })
      .type(resource.publicContactsPosition);
  }

  if (resource.publicContactsPosition) {
    cy.get("#service_public_contacts_attributes_0_position")
      .clear({ force: true })
      .type(resource.publicContactsPosition);
  }

  if (resource.contactHepldeskEmail) {
    cy.get("#service_helpdesk_email").clear({ force: true }).type(resource.contactHepldeskEmail);
  }

  if (resource.contactSecurityContactEmail) {
    cy.get("#service_security_contact_email").clear({ force: true }).type(resource.contactSecurityContactEmail);
  }

  if (resource.maturityLifeCycleStatus) {
    cy.get("#maturity-header").click();
  }

  if (resource.maturityLifeCycleStatus) {
    selectItemsMultipleChoice(resource.maturityLifeCycleStatus, ".service_life_cycle_statuses");
  }

  if (resource.marturityCertyfication) {
    cy.get("#service_certifications_0").clear({ force: true }).type(resource.marturityCertyfication);
  }

  if (resource.maturityStandards) {
    cy.get("#service_standards_0").clear({ force: true }).type(resource.maturityStandards);
  }

  if (resource.maturityOpenSourceTechnology) {
    cy.get("#service_open_source_technologies_0").clear({ force: true }).type(resource.maturityOpenSourceTechnology);
  }

  if (resource.maturityVersion) {
    cy.get("#service_version").clear({ force: true }).type(resource.maturityVersion);
  }

  if (resource.maturityChangelog) {
    cy.get("#service_changelog_0").clear({ force: true }).type(resource.maturityChangelog);
  }

  if (resource.dependenciesRequiredResources) {
    cy.get("#dependencies-header").click();
  }

  if (resource.dependenciesRequiredResources) {
    selectItemsMultipleChoice(resource.dependenciesRequiredResources, ".service_required_services");
  }

  if (resource.dependenciesRelatedResources) {
    selectItemsMultipleChoice(resource.dependenciesRelatedResources, ".service_related_services");
  }

  if (resource.dependenciesPlatformsInternal) {
    selectItemsMultipleChoice(resource.dependenciesPlatformsInternal, ".service_platforms");
  }

  if (resource.attributionFundingBodies) {
    cy.get("#attribution-header").click();
  }

  if (resource.attributionFundingBodies) {
    selectItemsMultipleChoice(resource.attributionFundingBodies, ".service_funding_bodies");
  }

  if (resource.attributionFundingPrograms) {
    selectItemsMultipleChoice(resource.attributionFundingPrograms, ".service_funding_programs");
  }

  if (resource.attributionGrantProjectNames) {
    cy.get("#service_grant_project_names_0").clear({ force: true }).type(resource.attributionGrantProjectNames);
  }

  if (resource.managementHeldeskUrl) {
    cy.get("#management-header").click();
  }

  if (resource.managementHeldeskUrl) {
    cy.get("#service_helpdesk_url").clear({ force: true }).type(resource.managementHeldeskUrl);
  }

  if (resource.managementManualUrl) {
    cy.get("#service_manual_url").clear({ force: true }).type(resource.managementManualUrl);
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

  if (resource.managementSlaUrl) {
    cy.get("#service_resource_level_url").clear({ force: true }).type(resource.managementSlaUrl);
  }

  if (resource.managementTrainingInformationUrl) {
    cy.get("#service_training_information_url").clear({ force: true }).type(resource.managementTrainingInformationUrl);
  }

  if (resource.managementStatusMonitoringUrl) {
    cy.get("#service_status_monitoring_url").clear({ force: true }).type(resource.managementStatusMonitoringUrl);
  }

  if (resource.managementMaintenanceUrl) {
    cy.get("#service_maintenance_url").clear({ force: true }).type(resource.managementMaintenanceUrl);
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

  if (resource.financialPaymentModelUrl) {
    cy.get("#financial-header").click();
  }

  if (resource.financialPaymentModelUrl) {
    cy.get("#service_payment_model_url").clear({ force: true }).type(resource.financialPaymentModelUrl);
  }

  if (resource.financialPricingUrl) {
    cy.get("#service_pricing_url").clear({ force: true }).type(resource.financialPricingUrl);
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
    "Target Users",
    "Access Types",
    "Access Modes",
    "Tags",
    "Availability and Language",
    "Geographic Locations",
    "Languages",
    "Marketing",
    "Multimedia",
    "Use Case",
    "Dependencies",
    "Required Services",
    "Suggested compatible services",
    "Platforms",
    "Attribution",
    "Funding Bodies",
    "Funding Programs",
    "Grant Project Names",
    "Order",
    "Order type",
    "Order url",
    "Public Contacts",
    "Maturity Information",
    "Life Cycle Status",
    "Certifications",
    "Standards",
    "Open Source Technologies",
    "Version",
    "Helpdesk",
    "Manual",
    "Terms of use",
    "Privacy policy",
    "Access policies",
    "Training information",
    "Maintenance",
    "Financial Information",
    "Payment Model",
    "Pricing",
    "Changelog",
  ];

  for (const value of resourceDetails) {
    cy.contains(value).should("be.visible");
  }
});

Cypress.Commands.add("hasResourceAbout", () => {
  const resourceAbout = ["Target Users", "Availability and Language", "Suggested compatible services"];

  for (const value of resourceAbout) {
    cy.contains(value).should("be.visible");
  }
});
