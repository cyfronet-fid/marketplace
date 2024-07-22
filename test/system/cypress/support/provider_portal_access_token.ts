/**
 * Define new commands types for typescript (for autocompletion)
 */
export {};

declare global {
  namespace Cypress {
    interface Chainable {
      getAccessToken(): Cypress.Chainable<void>;
    }
  }
}

Cypress.Commands.add("getAccessToken", () => {
  const refreshToken = Cypress.env("PROVIDER_PORTAL_REFRESH_TOKEN");
  const clientId = Cypress.env("PROVIDER_PORTAL_CLIENT_ID");
  const aaiTokenUrl = Cypress.env("AAI_TOKEN_URL");

  cy.request({
    method: "POST",
    url: aaiTokenUrl,
    form: false,

    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: {
      grant_type: "refresh_token",
      refresh_token: refreshToken,
      client_id: clientId,
      scope: "openid email profile",
    },
  }).then((response) => {
    let token = response.body.access_token;
    Cypress.env("PROVIDER_PORTAL_ACCESS_TOKEN", token);
  });
});
