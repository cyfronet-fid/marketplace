import { Utilities } from "../support/utilities";

const providerName = Utilities.getRandomString(8).toLocaleLowerCase();

export const providerJson = {
  name: providerName,
  abbreviation: providerName,
  website: "https://example.com",
  legalEntity: true,
  legalStatus: "provider_legal_status-foundation",
  hostingLegalEntity: "provider_hosting_legal_entity-eudat",
  description: "description",
  logo: "https://example.com",
  multimedia: [
    {
      multimediaURL: "https://example.com",
      multimediaName: "Multimedia Name",
    },
  ],
  scientificDomains: [
    {
      scientificDomain: "scientific_domain-humanities",
      scientificSubdomain: "scientific_subdomain-humanities-other_humanities",
    },
  ],
  tags: ["tags"],
  location: {
    streetNameAndNumber: "Street name and number",
    postalCode: "Postal Code 123",
    city: "City",
    region: "Region",
    country: "DE",
  },
  mainContact: {
    firstName: "MC First Name",
    lastName: "MC Last Name",
    email: "test@mail.pl",
    phone: "1234567890",
    position: "Position",
  },
  publicContacts: [
    {
      firstName: "PC First Name",
      lastName: "PC Last Name",
      email: "test@mail.pl",
      phone: "1234567890",
      position: "Position",
    },
  ],
  lifeCycleStatus: "provider_life_cycle_status-operational",
  certifications: ["Certifications Value"],
  participatingCountries: ["FR"],
  affiliations: ["Affiliations Value"],
  networks: ["provider_network-wds"],
  catalogueId: "eosc",
  structureTypes: ["provider_structure_type-virtual"],
  esfriDomains: ["provider_esfri_domain-physical_sciences_and_engineering"],
  esfriType: "provider_esfri_type-landmark",
  merilScientificDomains: [
    {
      merilScientificDomain: "provider_meril_scientific_domain-other",
      merilScientificSubdomain: "provider_meril_scientific_subdomain-other-other",
    },
  ],
  areasOfActivity: ["provider_area_of_activity-applied_research"],
  societalGrandChallenges: ["provider_societal_grand_challenge-environment"],
  nationalRoadmaps: ["National Roadmaps Value"],
  users: [
    {
      email: "test@mail.pl",
      id: "",
      name: "User - Name",
      surname: "User - Surname",
    },
  ],
};
