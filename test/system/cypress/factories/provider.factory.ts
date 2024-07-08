import { Utilities } from "../support/utilities";

export class IProviders {
  basicName: string;
  basicAbbreviation: string;
  basicWebpage_url: string;
  marketingDescription: string;
  classificationScientificDomains: string[];
  classificationTagList: string;
  locationStreet: string;
  locationPostCode: string;
  locationCity: string;
  locationCountry: string;
  contactFirstname: string;
  contactLastname: string;
  contactEmail: string;
  publicContactsEmail: string;
  adminFirstName?: string;
  adminLastName?: string;
  adminEmail?: string;
}

export const ProvidersFactory = {
  create: (args: { [field: string]: string } = {}): IProviders => ({
    basicName: Utilities.getUUID4(),
    basicAbbreviation: Utilities.getUUID4(),
    basicWebpage_url: "http://example.org/",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationTagList: Utilities.getRandomString(8).toLowerCase(),
    locationStreet: Utilities.getRandomString(8).toLowerCase(),
    locationPostCode: Utilities.getRandomString(8).toLowerCase(),
    locationCity: Utilities.getRandomString(8).toLowerCase(),
    locationCountry: "Poland",
    contactFirstname: Utilities.getRandomString(8).toLowerCase(),
    contactLastname: Utilities.getRandomString(8).toLowerCase(),
    contactEmail: Utilities.getRandomEmail(),
    publicContactsEmail: Utilities.getRandomEmail(),
    ...args,
  }),
};

export class IProvidersExtended extends IProviders {
  basicHostingLegalEntity: string;
  marketingMultimedia: string;
  classificationScientificDomains: string[];
  classificationStructureTypes: string[];
  locationRegion: string;
  contactPhone: string;
  contactPosition: string;
  publicContactsFirstName: string;
  publicContactsLastName: string;
  publicContactsPhone: string;
  publicContactsPosition: string;
  maturityProviderLifeCycleStatus: string;
  maturityCertifications: string;
  dependenciesParticipatingCountries: string[];
  dependenciesAffiliations: string;
  dependenciesNetworks: string[];
  otherESFRIDomains: string[];
  otherESFRIType: string;
  otherMerilScientificDomains: string[];
  otherAreasOfActivity: string[];
  otherSocietalGrandChallenges: string[];
  otherNationalRoadmaps: string;
}

export const ProvidersFactoryExtended = {
  create: (args: { [field: string]: string } = {}): IProvidersExtended => ({
    basicHostingLegalEntity: "100 Percent IT",
    basicName: Utilities.getUUID4(),
    basicAbbreviation: Utilities.getUUID4(),
    basicWebpage_url: "http://example.org/",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    marketingMultimedia: "http://example.org/",
    classificationScientificDomains: ["Agricultural Sciences ⇒ Agricultural Biotechnology"],
    classificationTagList: Utilities.getRandomString(8).toLowerCase(),
    classificationStructureTypes: ["Distributed"],
    locationStreet: Utilities.getRandomString(8).toLowerCase(),
    locationPostCode: Utilities.getRandomString(8).toLowerCase(),
    locationCity: Utilities.getRandomString(8).toLowerCase(),
    locationRegion: Utilities.getRandomString(8).toLowerCase(),
    locationCountry: "Poland",
    contactFirstname: Utilities.getRandomString(8).toLowerCase(),
    contactLastname: Utilities.getRandomString(8).toLowerCase(),
    contactEmail: Utilities.getRandomEmail(),
    contactPhone: Utilities.getRandomString(),
    contactPosition: Utilities.getRandomString(),
    publicContactsFirstName: Utilities.getRandomString(8).toLowerCase(),
    publicContactsLastName: Utilities.getRandomString(8).toLowerCase(),
    publicContactsEmail: Utilities.getRandomEmail(),
    publicContactsPhone: Utilities.getRandomString(),
    publicContactsPosition: Utilities.getRandomString(),
    maturityProviderLifeCycleStatus: "Operational",
    maturityCertifications: Utilities.getRandomString(),
    dependenciesParticipatingCountries: ["Poland"],
    dependenciesAffiliations: Utilities.getRandomString(),
    dependenciesNetworks: ["AErosol Robotic NETwork (AERONET)"],
    otherESFRIDomains: ["Energy"],
    otherESFRIType: "Landmark",
    otherMerilScientificDomains: ["Biological & Medical Sciences ⇒ Animal Facilities"],
    otherAreasOfActivity: ["Basic Research"],
    otherSocietalGrandChallenges: ["Transport"],
    otherNationalRoadmaps: Utilities.getRandomString(),
    ...args,
  }),
};
