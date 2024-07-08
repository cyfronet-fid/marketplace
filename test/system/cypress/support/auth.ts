/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IUser } from "../factories/user.factory";

export {}; // Hack for global access
declare global {
  namespace Cypress {
    interface Chainable {
      jiraLogin(): Cypress.Chainable<void>;
      jiraLogout(): Cypress.Chainable<void>;

      setSessionId(user: IUser, preserveUser: boolean): Cypress.Chainable<string>;
      loginAs(user: IUser, preserveUser?: boolean): Cypress.Chainable<void>;
      logout(): Cypress.Chainable<void>;
      openUserDropdown(): Cypress.Chainable<void>;
    }
  }
}

/**
 * App auth
 */
let TEMP_SESSIONID = null;
const APP_SESSION_COOKIE_NAME = "_mp_session";
Cypress.Commands.add("setSessionId", (user: IUser, preserveUser) => {
  if (!!TEMP_SESSIONID && preserveUser) {
    cy.setCookie(APP_SESSION_COOKIE_NAME, TEMP_SESSIONID);
    return cy.wrap(TEMP_SESSIONID);
  }

  const authMockUrl = "/users/login";
  cy.request({
    method: "GET",
    url: authMockUrl,
    body: user,
  })
    .then((response) => {
      const cookies = response.headers["set-cookie"] as string[];
      const sessionId = cookies
        .find((cookie) => cookie.includes(APP_SESSION_COOKIE_NAME))
        .split(";")
        .find((cookiesPart) => cookiesPart.includes(APP_SESSION_COOKIE_NAME))
        .split("=")
        .pop();
      cy.setCookie(APP_SESSION_COOKIE_NAME, sessionId);
      TEMP_SESSIONID = sessionId;
      return cy.wrap(TEMP_SESSIONID);
    })
    .as("sessionId");
  return cy.get("@sessionId");
});
Cypress.Commands.add("loginAs", function (user: IUser, preserveUser: boolean = false) {
  cy.setSessionId(user, preserveUser);
  cy.reload();
  cy.get(".eosc-common.top.white-label .right-links").should("be.visible");
});

Cypress.Commands.add("openUserDropdown", function () {
  cy.get('a[data-e2e="my-eosc-button"').click();
});

Cypress.Commands.add("logout", () => {
  cy.clearCookie(APP_SESSION_COOKIE_NAME);
  cy.reload();
  cy.get('a[data-e2e="login"]').should("be.visible");
});

/**
 * JIRA
 */
Cypress.Commands.add("jiraLogin", () => {
  expect(Cypress.env("MP_JIRA_URL")).to.be.a("string");
  expect(Cypress.env("JIRA_TEST_USER")).to.be.a("string");

  const loginPath = "/login.jsp?os_destination=%2Fdefault.jsp";
  cy.visit(Cypress.env("MP_JIRA_URL") + loginPath);

  const dashboardPath = "/secure/Dashboard.jspa";
  cy.get("#login-form-username").type(Cypress.env("JIRA_TEST_USER"));
  cy.get("#login-form-password").type(Cypress.env("JIRA_TEST_USER_PWD"));
  cy.get("#login-form-submit").click();

  cy.location("pathname").should("equal", dashboardPath);
});
Cypress.Commands.add("jiraLogout", () => {
  expect(Cypress.env("MP_JIRA_URL")).to.be.a("string");
  cy.location("origin").should("equal", Cypress.env("MP_JIRA_URL"));

  cy.clearCookie("JSESSIONID");
  cy.reload();
});
