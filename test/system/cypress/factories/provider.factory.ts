import {Utilities} from "../support/utilities";

export class IProviders {
    basicName: string;
    basicAbbreviation: string;
    basicWebpage_url: string;
    marketingDescription: string;
    classificationScientificDomains: string[];
    classificationTag: string;
    locationStreet:string;
    locationPostCode:string;
    locationCity:string;
    locationCountry:string;
    contactFirstname:string;
    contactLastname:string;
    contactEmail:string;
    publicContactsEmail:string;
    adminFirstName?:string;
    adminLastName?:string;
    adminEmail?:string;
}

export const ProvidersFactory = {
    create: (args: {[field: string]: string} = {}): IProviders => ({
        basicName: Utilities.getUUID4(),
        basicAbbreviation: Utilities.getUUID4(),
        basicWebpage_url: 'https://example.org/',
        marketingDescription: Utilities.getRandomString(8).toLowerCase(),
        classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
        classificationTag: Utilities.getRandomString(8).toLowerCase(),
        locationStreet:Utilities.getRandomString(8).toLowerCase(),
        locationPostCode:Utilities.getRandomString(8).toLowerCase(),
        locationCity:Utilities.getRandomString(8).toLowerCase(),
        locationCountry:"Poland",
        contactFirstname:Utilities.getRandomString(8).toLowerCase(),
        contactLastname:Utilities.getRandomString(8).toLowerCase(),
        contactEmail:Utilities.getRandomEmail(),
        publicContactsEmail:Utilities.getRandomEmail(),
        ...args
    })
};

export class IProvidersExtended extends IProviders {
  marketingMultimedia: string;
  classificationScientificDomains: string[];
  locationRegion:string;
  contactPhone:string;
  contactPosition:string;
  publicContactsFirstName:string;
  publicContactsLastName:string;
  publicContactsPhone:string;
  publicContactsPosition:string;
  maturityProviderLifeCycleStatus:string[];
  maturityCertifications:string;
  otherHostingLegalEntity:string;
  otherParticipatingCountries:string[];
  otherAffiliations:string;
  otherNetworks:string[];
  otherStructureTypes:string[];
  otherESFRIDomains:string[];
  otherESFRIType:string[];
  otherMerilScientificDomains:string[];
  otherAreasOfActivity:string[];
  otherSocietalGrandChallenges:string[];
  otherNationalRoadmaps:string;
}

export const ProvidersFactoryExtended = {
  create: (args: {[field: string]: string} = {}): IProvidersExtended => ({
      basicName: Utilities.getUUID4(),
      basicAbbreviation: Utilities.getUUID4(),
      basicWebpage_url: 'https://example.org/',
      marketingDescription: Utilities.getRandomString(8).toLowerCase(),
      marketingMultimedia: 'https://example.org/',
      classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
      classificationTag: Utilities.getRandomString(8).toLowerCase(),
      locationStreet:Utilities.getRandomString(8).toLowerCase(),
      locationPostCode:Utilities.getRandomString(8).toLowerCase(),
      locationCity:Utilities.getRandomString(8).toLowerCase(),
      locationRegion:Utilities.getRandomString(8).toLowerCase(),
      locationCountry:"Poland",
      contactFirstname:Utilities.getRandomString(8).toLowerCase(),
      contactLastname:Utilities.getRandomString(8).toLowerCase(),
      contactEmail:Utilities.getRandomEmail(),
      contactPhone: Utilities.getRandomString(),
      contactPosition: Utilities.getRandomString(),
      publicContactsFirstName:Utilities.getRandomString(8).toLowerCase(),
      publicContactsLastName:Utilities.getRandomString(8).toLowerCase(),
      publicContactsEmail:Utilities.getRandomEmail(),
      publicContactsPhone: Utilities.getRandomString(),
      publicContactsPosition: Utilities.getRandomString(),
      maturityProviderLifeCycleStatus: ["Operational"],
      maturityCertifications:Utilities.getRandomString(),
      otherHostingLegalEntity:Utilities.getRandomString(),
      otherParticipatingCountries: ["Poland"],
      otherAffiliations: Utilities.getRandomString(),
      otherNetworks:["AErosol Robotic NETwork (AERONET)"],
      otherStructureTypes:["Distributed"],
      otherESFRIDomains: ["Energy"],
      otherESFRIType: ["Landmark"],
      otherMerilScientificDomains:["Biological & Medical Sciences ⇒ Animal Facilities"],
      otherAreasOfActivity: ["Basic Research"],
      otherSocietalGrandChallenges:["Transport"],
      otherNationalRoadmaps:Utilities.getRandomString(),
      ...args
  })
};
