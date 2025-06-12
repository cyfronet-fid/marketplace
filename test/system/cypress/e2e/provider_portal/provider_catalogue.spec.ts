import { confEnv } from "../../support/provider_portal_env";
import { providerJson } from "../../fixtures/provider_playload";
import { resourceJson } from "../../fixtures/resource_playload";

before(() => {
  cy.getAccessToken();
});

describe("Provider Portal - create provider, resource for other catalogue than eosc", () => {
  it(
    "create provider, resource for other catalogue than eosc and delete provider",
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
      const provider = { ...providerJson, catalogueId: "cyfronet_catalogue" };
      const resource = { ...resourceJson, resourceOrganisation: provider.name, catalogueId: "cyfronet_catalogue" };
      const catalogue = "cyfronet_catalogue";

      cy.request({
        method: "POST",
        url: `${providerPortalURL}/api/catalogue/${catalogue}/provider`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(provider),
      });

      cy.visitPage(marketplaceURL);
      cy.checkVisibilityOfProviderInMarketplace(provider.name);
      cy.get("[data-e2e='provider-details-btn']").click();
      cy.checkVisibilityOfProviderDetails();
      cy.get("[data-e2e='provider-about-btn']").click();
      cy.checkVisibilityOfProviderAbout();

      cy.request({
        method: "POST",
        url: `${providerPortalURL}/api/catalogue/${catalogue}/resource`,
        form: false,

        headers: {
          Authorization: authorization,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(resource),
      });

      cy.visitPage(marketplaceURL);
      cy.checkVisibilityOfResourceInMarketplace(resource.name);
      cy.checkVisibilityOfResourceAbout();
      cy.get("[data-e2e='service-details-btn']").click();
      cy.checkVisibilityOfResourceDetails();

      cy.request({
        method: "DELETE",
        url: `${providerPortalURL}/api/catalogue/${catalogue}/provider/${provider.name}`,
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
