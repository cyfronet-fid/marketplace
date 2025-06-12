const confEnv = {
  PROVIDER_PORTAL_ACCESS_TOKEN: () => Cypress.env("PROVIDER_PORTAL_ACCESS_TOKEN"),
  PROVIDER_PORTAL_URL: () => Cypress.env("PROVIDER_PORTAL_URL"),
  MARKETPLACE_URL: () => Cypress.env("MARKETPLACE_URL"),
};

export { confEnv };
