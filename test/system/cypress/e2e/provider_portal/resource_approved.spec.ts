import { confEnv } from "../../support/provider_portal_env";
import { providerJson } from "../../fixtures/provider_playload";
import { resourceJson } from "../../fixtures/resource_playload";

before(() => {
  cy.getAccessToken();
});

describe("Provider Portal - approved resource", () => {
  it(
    "add first resource, aprove, deactive, active and delete it",
    {
      retries: {
        runMode: 0,
      },
      tags: "@integration-PC-tests",
    },
    () => {
      const token = confEnv.PROVIDER_PORTAL_ACCESS_TOKEN();
      const providerPortalURL = confEnv.PROVIDER_PORTAL_URL();
      const marketplaceURL = confEnv.MARKETPLACE_URL();
      const authorization = `Bearer ${token}`;
      const provider = providerJson;
      const resource = { ...resourceJson, resourceOrganisation: provider.name };

      cy.request({
        method: "POST",
        url: `${providerPortalURL}/api/provider/`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(provider),
      });

      cy.request({
        method: "PATCH",
        url: `${providerPortalURL}/api/provider/verifyProvider/${provider.name}?active=true&status=approved provider`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
      });

      cy.request({
        method: "POST",
        url: `${providerPortalURL}/api/resource`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(resource),
      });

      cy.visitPage(marketplaceURL);
      cy.checkInvisibilityOfResourceInMarketplace(resource.name);

      cy.request({
        method: "PATCH",
        url: `${providerPortalURL}/api/resource/verifyResource/${provider.name}.${resource.name}?active=true&status=approved resource`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
      });

      cy.visitPage(marketplaceURL);
      cy.checkVisibilityOfResourceInMarketplace(resource.name);
      cy.checkVisibilityOfResourceAbout();
      cy.get("[data-e2e='service-details-btn']").click();
      cy.checkVisibilityOfResourceDetails();

      cy.request({
        method: "PATCH",
        url: `${providerPortalURL}/api/resource/verifyResource/${provider.name}.${resource.name}?active=false&status=approved resource`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
      });

      cy.visitPage(marketplaceURL);
      cy.checkInvisibilityOfResourceInMarketplace(resource.name);

      cy.request({
        method: "PATCH",
        url: `${providerPortalURL}/api/resource/verifyResource/${provider.name}.${resource.name}?active=true&status=approved resource`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
      });

      cy.visitPage(marketplaceURL);
      cy.checkInvisibilityOfResourceInMarketplace(resource.name);

      cy.request({
        method: "DELETE",
        url: `${providerPortalURL}/api/provider/${provider.name}`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
      });

      cy.visitPage(marketplaceURL);
      cy.checkInvisibilityOfProviderInMarketplace(provider.name);

      cy.visitPage(marketplaceURL);
      cy.checkInvisibilityOfResourceInMarketplace(resource.name);
    },
  );
});
