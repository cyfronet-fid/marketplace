import { Utilities } from "../support/utilities";

export class IProviders {
  basicName: string;
  basicAbbreviation: string;
  basicWebpage_url: string;
  marketingDescription: string;
  locationCountry: string;
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
    locationCountry: "Poland",
    publicContactsEmail: Utilities.getRandomEmail(),
    ...args,
  }),
};

export class IProvidersExtended extends IProviders {
  basicHostingLegalEntity: string;
}

export const ProvidersFactoryExtended = {
  create: (args: { [field: string]: string } = {}): IProvidersExtended => ({
    basicHostingLegalEntity: "100 Percent IT",
    basicName: Utilities.getUUID4(),
    basicAbbreviation: Utilities.getUUID4(),
    basicWebpage_url: "http://example.org/",
    marketingDescription: Utilities.getRandomString(8).toLowerCase(),
    locationCountry: "Poland",
    publicContactsEmail: Utilities.getRandomEmail(),
    ...args,
  }),
};
