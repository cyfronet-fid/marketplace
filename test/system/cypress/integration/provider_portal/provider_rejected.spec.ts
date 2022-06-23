import { providerJson } from "../../fixtures/provider_playload"

describe("Provider Portal - rejecte provider", () => {

  const token = Cypress.env("PROVIDER_PORTAL_ACCESS_TOKEN");
  const providerPortalURL = Cypress.env("PROVIDER_PORTAL_URL");
  const marketplaceURL = Cypress.env("MARKETPLACE_URL");
  const authorization = `Bearer ${token}`;
  const provider = providerJson

  it("create provider,  reject, approve and delete it", { tags: '@integration-PC-tests' }, () => {
    cy.visit(`${marketplaceURL}`);

    cy.request({
      method: 'POST',
      url: `${providerPortalURL}/api/provider/`,
      form: false,

      headers: {
        Authorization: authorization,
        "Content-Type": "application/json"
      },
      body: (JSON.stringify(provider))
    });

    cy.visit(`${marketplaceURL}`);
    cy.checkInvisibilityOfProviderInMarketplace(provider.name)


    cy.request({
      method: 'PATCH',
      url: `${providerPortalURL}/api/provider/verifyProvider/${provider.name}?active=true&status=rejected provider`,
      form: false,

      headers: {
        Authorization: authorization,
        "Content-Type": "application/json"
      }
    });

    cy.visit(`${marketplaceURL}`);
    cy.checkInvisibilityOfProviderInMarketplace(provider.name)



    cy.request({
      method: 'PATCH',
      url: `${providerPortalURL}/api/provider/verifyProvider/${provider.name}?active=true&status=approved provider`,
      form: false,

      headers: {
        Authorization: authorization,
        "Content-Type": "application/json"
      }
    });

    cy.visit(`${marketplaceURL}`);
    cy.checkVisibilityOfProviderInMarketplace(provider.name)

    cy.request({
      method: 'DELETE',
      url: `${providerPortalURL}/api/provider/${provider.name}`,
      form: false,

      headers: {
        Authorization: authorization,
        "Content-Type": "application/json"
      }
    });

    cy.visit(`${marketplaceURL}`);
    cy.checkInvisibilityOfProviderInMarketplace(provider.name)

  });
});

