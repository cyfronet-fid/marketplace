/**
 * Define new commands types for typescript (for autocompletion)
 */
import { IProject } from "../factories/project.factory";

export type accessType = "open access" | "fully open access" | "order required" | "other";
export interface IResource {
  name: string;
  accessType: accessType;
  projectName: string;
}
declare global {
  namespace Cypress {
    interface Chainable {
      /**
       * Return projectData object with project details
       */
      fillFormProject(project: Partial<IProject>): Cypress.Chainable<void>;

      /**
       * Compare project details with data on site
       */
      hasProjectDetails(project: IProject): Cypress.Chainable<void>;

      /**
       * Get data of resource from web page
       */
      scrapResourceDetails(): Cypress.Chainable<IResource>;
    }
  }
}

Cypress.Commands.add("fillFormProject", (project: IProject) => {
  if (project.name) {
    cy.get("#project_name").clear().type(project.name);
  }

  if (project.reason) {
    cy.get("#project_reason_for_access").clear().type(project.reason);
  }

  // clear domains list
  cy.get(".project_scientific_domains").then(($el) => {
    $el
      .find(".choices__item--selectable")
      .find(".choices__button")
      .each((index, $btn) => $btn.click());
  });
  if (project.scientificDomains && project.scientificDomains.length > 0) {
    project.scientificDomains.forEach((domain) => {
      cy.get(".project_scientific_domains").find('.choices__input[type="search"]').type(domain).type("{enter}");
      cy.get(".project_scientific_domains")
        .find(".choices__item.choices__item--selectable")
        .contains(domain)
        .should("exist");
    });
  }

  if (project.additionalInformation) {
    cy.get("#project_additional_information")
      .clear({ force: true })
      .type(project.additionalInformation, { force: true });
  }

  if (project.customerTypology) {
    cy.get("#project_customer_typology").select(project.customerTypology);
  }

  if (project.email) {
    cy.get("#project_email").clear().type(project.email);
  }

  if (project.organization) {
    cy.get("#project_organization").clear().type(project.organization);
  }

  if (project.department) {
    cy.get("#project_department").clear().type(project.department);
  }

  if (project.countryOfOrigin) {
    cy.get("#project_country_of_origin").select(project.countryOfOrigin);
  }

  if (project.webpage) {
    cy.get("#project_webpage").clear().type(project.webpage);
  }

  cy.get("body").then(($body) => {
    const hasCaptcha = $body.find("iframe").length > 0;
    if (hasCaptcha) {
      cy.checkCaptcha();
    }
  });
});
Cypress.Commands.add("hasProjectDetails", (project: IProject) => {
  cy.location("pathname").should("match", /\/projects\/[0-9]+/);
  cy.get(".services-menu").find(".nav-link").contains("project details", { matchCase: false }).click();
  cy.get(".project-heading")
    .invoke("text")
    .should("contain", project.customerTypology)
    .should("contain", project.organization)
    .should("contain", project.name);
  cy.get(".additional-information")
    .invoke("text")
    .then((text) =>
      Object.keys(project).forEach((key) =>
        Array.isArray(project[key])
          ? project[key].forEach((value) => expect(text).to.contain(value))
          : expect(text).to.contain(project[key]),
      ),
    );
});
Cypress.Commands.add("scrapResourceDetails", () => {
  cy.location("pathname").should("match", /\/projects\/[0-9]+\/services\/[0-9]+/);

  cy.get(".details").contains("dl", "Service name:").find("dd").invoke("text").as("name");
  cy.get(".details").contains("dl", "Service access:").find("dd").invoke("text").as("accessType");
  cy.get(".details").contains("dl", "Project name:").find("dd").invoke("text").as("projectName");

  return cy.getAll("@name", "@accessType", "@projectName");
});
