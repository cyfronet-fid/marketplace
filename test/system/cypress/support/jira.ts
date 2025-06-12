/**
 * Define new commands types for typescript (for autocompletion)
 */
export interface IJiraResource {
  name: string;
  status: string;
}
export type findTicketBy = null | "name" | "key";
export type ticketValuesLabels =
  | "type"
  | "status"
  | "priority"
  | "resolution"
  | "epic name"
  | "ci-displayName"
  | "ci-name"
  | "ci-surname"
  | "ci-email"
  | "ci-institution"
  | "ci-department"
  | "ci-departmentalWebPage"
  | "cp-customerTypology"
  | "so-projectName"
  | "cp-collaborationCountry"
  | "cp-customerCountry"
  | "eosc-hub test"
  | "cp-scientificDiscipline";
export type ticketOrderType = ticketValuesLabels | "created" | "updated";
declare global {
  namespace Cypress {
    interface Chainable {
      /**
       * Tickets
       */
      jiraGetTicketsBy(type: findTicketBy, value): Cypress.Chainable<JQuery<HTMLElement>>;
      jiraFindTicketBy(type: findTicketBy, value): Cypress.Chainable<JQuery<HTMLElement>>;
      jiraGetTicketDetailFrom(label: ticketValuesLabels): Cypress.Chainable<JQuery<HTMLElement>>;
      jiraOrderTicketsBy(orderType: ticketOrderType): Cypress.Chainable<void>;
      jiraGetResources(): Cypress.Chainable<IJiraResource[]>;

      /**
       * Comments
       */
      jiraGetTicketComments(): Cypress.Chainable<JQuery<HTMLElement>>;
      jiraGetCommentDate(): Cypress.Chainable<string>;
      jiraGetCommentText(): Cypress.Chainable<string>;
    }
  }
}

/**
 * Tickets
 */
Cypress.Commands.add("jiraGetTicketsBy", (type: findTicketBy, value) => {
  switch (type) {
    case null:
      return cy.get(".issue-list > li");
    case "name":
      return cy.get(".issue-list").find('li[title="' + value + '"]');
    case "key":
      return cy.get(".issue-list").contains(".issue-link-key", value);
    default:
      throw "Not supported filtration type, please update support/jira.ts file";
  }
});
Cypress.Commands.add("jiraFindTicketBy", (type: findTicketBy, value) => {
  return cy.jiraGetTicketsBy(type, value).first();
});
Cypress.Commands.add("jiraGetTicketDetailFrom", (label: ticketValuesLabels) => {
  cy.location("pathname").should("include", "/projects/" + Cypress.env("MP_JIRA_PROJECT") + "/issues/");

  return cy.get(".property-list").contains(".item", label, { matchCase: false }).find(".value");
});
Cypress.Commands.add("jiraGetEpicIssues", () => {
  cy.jiraGetTicketDetailFrom("type").invoke("text").should("equal", "Epic");

  return cy.get(".issuerow");
});
Cypress.Commands.add("jiraOrderTicketsBy", (orderType: ticketOrderType) => {
  cy.get(".order-options").click();
  cy.get("#order-by-options-input").type(orderType);
  cy.get("#order-by-options-multi-select").then(($el) => {
    const isSetAlready = $el.find(".no-suggestions").length > 0;
    if (isSetAlready) {
      return;
    }

    cy.wrap($el).contains(".item-label", orderType, { matchCase: false }).click();
  });
});
Cypress.Commands.add("jiraGetResources", () => {
  return cy.get("#ghx-issues-in-epic-table").then(($el) => {
    const resources: IJiraResource[] = [];
    $el.find(".issuerow").each(function (index, $row) {
      resources.push({
        name: $row.querySelector(".ghx-summary").textContent.trim(),
        status: $row.querySelector(".status").textContent.toLowerCase().trim(),
      });
    });
    return cy.wrap(resources);
  });
});

/**
 * Comments
 */
Cypress.Commands.add("jiraGetTicketComments", () => {
  cy.location("pathname").should("match", /\/projects\/EOSCSO([A-Z]+)\/issues\/EOSCSO([A-Z]+)-[0-9]+\?.+/);

  cy.get("#comment-tabpanel").first().click();
  return cy.get("activity-comment");
});

Cypress.Commands.add("jiraGetCommentDate", { prevSubject: true }, (comment: JQuery<HTMLElement>) => {
  return cy.wrap(comment).find(".livestamp").invoke("text");
});

Cypress.Commands.add("jiraGetCommentText", { prevSubject: true }, (comment: JQuery<HTMLElement>) => {
  return cy.wrap(comment).find(".action-body.flooded").first().invoke("text");
});
