import { Utilities } from "../support/utilities";

export class IResources {
  basicName: string;
  basicResourceOrganisation: string;
  basicProviders: string[];
  basicWebpage_url: string;
  marketingDescription: string;
  classificationScientificDomains: string[];
  classificationCategories: string[];
  publicContactsEmail: string;
  maturityTrl: string[];
  orderOrdertype: string;
}

export const ResourcesFactory = {
  create: (args: { [field: string]: string } = {}): IResources => ({
    basicName: Utilities.getUUID4(),
    basicResourceOrganisation: "EGI Federation",
    basicProviders: ["EUDAT", "CloudFerro"],
    basicWebpage_url: "https://example.com",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationCategories: ["Access physical & eInfrastructures ⇒ Compute"],
    publicContactsEmail: Utilities.getRandomEmail(),
    maturityTrl: ["trl-1"],
    orderOrdertype: "order_required",
    ...args,
  }),
};

export class IResourcesExtended extends IResources {
  classificationAccessType: string[];
  classificationAccessMode: string[];
  classificationTagList: string;
  managementHeldeskUrl: string;
  managementManualUrl: string;
  managementTermsOfUseUrl: string;
  managementPrivacyPolicyUrl: string;
  managementAccessPoliciesUrl: string;
  orderUrl: string;
}

export const ResourcesFactoryExtended = {
  create: (args: { [field: string]: string } = {}): IResourcesExtended => ({
    basicName: Utilities.getUUID4(),
    basicResourceOrganisation: "EGI Federation",
    basicProviders: ["EUDAT", "CloudFerro"],
    basicWebpage_url: "https://example.com",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationCategories: ["Access physical & eInfrastructures ⇒ Compute"],
    classificationAccessType: ["Remote"],
    classificationAccessMode: ["Free"],
    classificationTagList: Utilities.getRandomString(8).toLowerCase(),
    publicContactsEmail: Utilities.getRandomEmail(),
    maturityTrl: ["trl-1"],
    managementHeldeskUrl: "https://example.com",
    managementManualUrl: "https://example.com",
    managementTermsOfUseUrl: "https://example.com",
    managementPrivacyPolicyUrl: "https://example.com",
    managementAccessPoliciesUrl: "https://example.com",
    orderOrdertype: "order_required",
    orderUrl: "https://example.com",
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
