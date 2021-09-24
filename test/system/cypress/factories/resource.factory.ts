import {Utilities} from "../support/utilities";

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
    availabilityGeographicalavailabilities: string[];
    availabilityLanguageavailability:string[];
    contactsFirstname:string;
    contactsLastname:string;
    contactsEmail:string;
    publicContactsEmail:string;
    maturityTrl:string[];
    orderOrdertype: string;
}

export const ResourcesFactory = {
    create: (args: {[field: string]: string} = {}): IResources => ({
        basicName: Utilities.getUUID4(),
        basicResourceOrganisation: "EGI Federation",
        basicProviders: ["EUDAT", "CloudFerro"],
        basicWebpage_url: Utilities.getRandomUrl(),
        marketingDescription: Utilities.getRandomString(8).toLowerCase(),
        marketingTagline: Utilities.getRandomEmail(),
        classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
        classificationCategories: ["Access physical & eInfrastructures ⇒ Compute"],
        classificationDedicatedFor: ["Businesses"],
        availabilityGeographicalavailabilities: ["Afghanistan"],
        availabilityLanguageavailability:["Abkhazian"],
        contactsFirstname:Utilities.getRandomString(8).toLowerCase(),
        contactsLastname:Utilities.getRandomString(8).toLowerCase(),
        contactsEmail:Utilities.getRandomEmail(),
        publicContactsEmail:Utilities.getRandomEmail(),
        maturityTrl:["trl-1"],
        orderOrdertype: 'order_required',
        ...args
    })
};

export class IOffers {
  name: string;
  description: string;
  orderType: string;
  internalOrder:boolean;
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
    orderTargetUrl:Utilities.getRandomUrl(),
    ...args,
  }),
};

export class IParameters {
  constantName: string;
  constantHint: string;
  constantValue: string;
  constantValueType:string;
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