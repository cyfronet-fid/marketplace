import { Utilities } from "../support/utilities";

export class IResources {
  basicName: string;
  basicResourceOrganisation: string;
  basicProviders: string[];
  basicWebpage_url: string;
  marketingDescription: string;
  marketingTagline: string;
  classificationScientificDomains: string[];
  classificationCategories: string[];
  classificationDedicatedFor: string[];
  availabilityGeographicalAvailabilities: string[];
  availabilityLanguageAvailability: string[];
  contactFirstname: string;
  contactLastname: string;
  contactEmail: string;
  publicContactsEmail: string;
  maturityTrl: string[];
  orderOrdertype: string;
}

export const ResourcesFactory = {
  create: (args: { [field: string]: string } = {}): IResources => ({
    basicName: Utilities.getUUID4(),
    basicResourceOrganisation: "EGI Federation",
    basicProviders: ["CLARIN ERIC", "CloudFerro"],
    basicWebpage_url: "https://example.com",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    marketingTagline: Utilities.getRandomEmail(),
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationCategories: ["Access physical & eInfrastructures ⇒ Compute"],
    classificationDedicatedFor: ["Businesses"],
    availabilityGeographicalAvailabilities: ["Afghanistan"],
    availabilityLanguageAvailability: ["Abkhazian"],
    contactFirstname: Utilities.getRandomString(8).toLowerCase(),
    contactLastname: Utilities.getRandomString(8).toLowerCase(),
    contactEmail: Utilities.getRandomEmail(),
    publicContactsEmail: Utilities.getRandomEmail(),
    maturityTrl: ["trl-1"],
    orderOrdertype: "order_required",
    ...args,
  }),
};

export class IResourcesExtended extends IResources {
  marketingMultimedia: string;
  marketingUseCasesUrl: string;
  classificationAccessType: string[];
  classificationAccessMode: string[];
  classificationTagList: string;
  locationResourceGeographicLocation: string[];
  contactPhone: string;
  contactOrganistation: string;
  constactPosition: string;
  publicContactsFirstName: string;
  publicContactsLastName: string;
  publicContactsPhone: string;
  publicContactsOrganisation: string;
  publicContactsPosition: string;
  contactHepldeskEmail: string;
  contactSecurityContactEmail: string;
  maturityLifeCycleStatus: string[];
  marturityCertyfication: string;
  maturityStandards: string;
  maturityOpenSourceTechnology: string;
  maturityVersion: string;
  maturityChangelog: string;
  dependenciesRequiredResources: string[];
  dependenciesRelatedResources: string[];
  dependenciesPlatformsInternal: string[];
  attributionFundingBodies: string[];
  attributionFundingPrograms: string[];
  attributionGrantProjectNames: string;
  managementHeldeskUrl: string;
  managementManualUrl: string;
  managementTermsOfUseUrl: string;
  managementPrivacyPolicyUrl: string;
  managementAccessPoliciesUrl: string;
  managementSlaUrl: string;
  managementTrainingInformationUrl: string;
  managementStatusMonitoringUrl: string;
  managementMaintenanceUrl: string;
  orderUrl: string;
  financialPaymentModelUrl: string;
  financialPricingUrl: string;
}

export const ResourcesFactoryExtended = {
  create: (args: { [field: string]: string } = {}): IResourcesExtended => ({
    basicName: Utilities.getUUID4(),
    basicResourceOrganisation: "EGI Federation",
    basicProviders: ["CLARIN ERIC", "CloudFerro"],
    basicWebpage_url: "https://example.com",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    marketingTagline: Utilities.getRandomString(8).toLowerCase(),
    marketingMultimedia: "https://example.com",
    marketingUseCasesUrl: "https://example.com",
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationCategories: ["Access physical & eInfrastructures ⇒ Compute"],
    classificationDedicatedFor: ["Businesses"],
    classificationAccessType: ["Remote"],
    classificationAccessMode: ["Free"],
    classificationTagList: Utilities.getRandomString(8).toLowerCase(),
    availabilityGeographicalAvailabilities: ["Afghanistan"],
    availabilityLanguageAvailability: ["Abkhazian"],
    locationResourceGeographicLocation: ["Albania"],
    contactFirstname: Utilities.getRandomString(8).toLowerCase(),
    contactLastname: Utilities.getRandomString(8).toLowerCase(),
    contactEmail: Utilities.getRandomEmail(),
    contactPhone: Utilities.getRandomString(8).toLowerCase(),
    contactOrganistation: Utilities.getRandomString(8).toLowerCase(),
    constactPosition: Utilities.getRandomString(8).toLowerCase(),
    publicContactsFirstName: Utilities.getRandomString(8).toLowerCase(),
    publicContactsLastName: Utilities.getRandomString(8).toLowerCase(),
    publicContactsEmail: Utilities.getRandomEmail(),
    publicContactsPhone: Utilities.getRandomString(8).toLowerCase(),
    publicContactsOrganisation: Utilities.getRandomString(8).toLowerCase(),
    publicContactsPosition: Utilities.getRandomString(8).toLowerCase(),
    contactHepldeskEmail: Utilities.getRandomEmail(),
    contactSecurityContactEmail: Utilities.getRandomEmail(),
    maturityTrl: ["trl-1"],
    maturityLifeCycleStatus: ["Implementation"],
    marturityCertyfication: Utilities.getRandomString(8).toLowerCase(),
    maturityStandards: Utilities.getRandomString(8).toLowerCase(),
    maturityOpenSourceTechnology: Utilities.getRandomString(8).toLowerCase(),
    maturityVersion: Utilities.getRandomString(8).toLowerCase(),
    maturityChangelog: Utilities.getRandomString(8).toLowerCase(),
    dependenciesRequiredResources: ["AMBER"],
    dependenciesRelatedResources: ["B2DROP"],
    dependenciesPlatformsInternal: ["CLARIN"],
    attributionFundingBodies: ["Academy of Finland (AKA)"],
    attributionFundingPrograms: ["Cohesion Fund (CF)"],
    attributionGrantProjectNames: Utilities.getRandomString(8).toLowerCase(),
    managementHeldeskUrl: "https://example.com",
    managementManualUrl: "https://example.com",
    managementTermsOfUseUrl: "https://example.com",
    managementPrivacyPolicyUrl: "https://example.com",
    managementAccessPoliciesUrl: "https://example.com",
    managementSlaUrl: "https://example.com",
    managementTrainingInformationUrl: "https://example.com",
    managementStatusMonitoringUrl: "https://example.com",
    managementMaintenanceUrl: "https://example.com",
    orderOrdertype: "order_required",
    orderUrl: "https://example.com",
    financialPaymentModelUrl: "https://example.com",
    financialPricingUrl: "https://example.com",
    ...args,
  }),
};

export class IOffers {
  name: string;
  description: string;
  orderType: string;
  internalOrder: boolean;
  orderAccessUrl: string;
  orderTargetUrl: string;
}

export const OfferFactory = {
  create: (args: { [field: string]: string } = {}): IOffers => ({
    name: Utilities.getUUID4(),
    description: Utilities.getRandomString(8).toLowerCase(),
    orderType: "order_required",
    internalOrder: false,
    orderAccessUrl: Utilities.getRandomUrl(),
    orderTargetUrl: Utilities.getRandomUrl(),
    ...args,
  }),
};

export class IParameters {
  constantName: string;
  constantHint: string;
  constantValue: string;
  constantValueType: string;
}

export const ParametersFactory = {
  create: (args: { [field: string]: string } = {}): IParameters => ({
    constantName: Utilities.getUUID4(),
    constantHint: Utilities.getRandomString(8).toLowerCase(),
    constantValue: Utilities.getRandomString(8).toLowerCase(),
    constantValueType: "string",
    ...args,
  }),
};
