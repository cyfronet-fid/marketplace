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
  multimedia: [],
  country: "DE",
  publicContacts: [
    {
      email: "test@mail.pl",
    },
  ],
  catalogueId: "eosc",
  nodePID: "node-egi",
  users: [
    {
      email: "test@mail.pl",
      id: "",
      name: "User - Name",
      surname: "User - Surname",
    },
  ],
};
