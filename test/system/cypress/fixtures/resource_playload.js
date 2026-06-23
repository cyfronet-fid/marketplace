import { Utilities } from "../support/utilities";

const resourceName = Utilities.getRandomString(8).toLocaleLowerCase();

export const resourceJson = {
  name: resourceName,
  abbreviation: resourceName,
  resourceOrganisation: "resource organisation",
  resourceProviders: [],
  webpage: "https://example.com",
  description: "description",
  logo: "https://example.com",
  scientificDomains: [
    {
      scientificDomain: "scientific_domain-humanities",
      scientificSubdomain: "scientific_subdomain-humanities-arts",
    },
  ],
  categories: [
    {
      category: "category-access_physical_and_eInfrastructures-compute",
      subcategory: "subcategory-access_physical_and_eInfrastructures-compute-orchestration",
    },
  ],
  accessTypes: ["access_type-mail_in"],
  tags: ["tags"],
  publicContacts: [
    {
      email: "test@mail.pl",
    },
  ],
  trl: "trl-1",
  catalogueId: "eosc",
  termsOfUse: "https://example.com",
  privacyPolicy: "https://example.com",
  accessPolicy: "https://example.com",
  orderType: "order_type-fully_open_access",
  order: "https://example.com",
};
