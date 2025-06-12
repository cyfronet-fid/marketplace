import { IUser, UserFactory } from "../factories/user.factory";
import { IProject, ProjectFactory } from "../factories/project.factory";
import { Utilities } from "../support/utilities";
import { accessType, IResource } from "../support/project";
import { IJiraResource } from "../support/jira";
import { IResources } from "../factories/resource.factory";

const user = JSON.stringify(UserFactory.create());
const project = ProjectFactory.create();
beforeEach(() => {
  cy.session([user, project], () => {
    cy.clearCookie("user");
    cy.setCookie("user", user, { domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, "") });
    cy.setCookie("user", user, { domain: Cypress.config().baseUrl.replace(/(^\w+:|^)\/\//, "") });
    cy.clearCookie("project");
    cy.setCookie("project", JSON.stringify(project), {
      domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, ""),
    });
    cy.setCookie("project", JSON.stringify(project), { domain: Cypress.config().baseUrl.replace(/(^\w+:|^)\/\//, "") });
  });
  cy.setCookie("resources", "[]");
  cy.setCookie("message", "SomeMessage");
});
describe("Integration with JIRA", { tags: "@extended-test" }, () => {
  // Hack: Before hook is running twice on baseUrl origin change
  // In that case "it" is used to run only once
  it("Should add project", () => {
    cy.visit("/");
    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            cy.loginAs(user, true);

            cy.visit("/projects/new");
            cy.fillFormProject(project);
            cy.contains("button", "Create new project").click();
            cy.hasProjectDetails(project);
          });
      });
  });
  it("Add open access", () => {
    cy.visit("/");
    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        console.log(cy.getCookie("project"));
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            cy.loginAs(user, true);
            cy.visit("/services");
            cy.get('select[name="order_type"]').select("open_access");
            cy.location("search").should("include", "order_type=open_access");
            cy.get(".service-box").first().find("h2").find("a").click();
            cy.location("pathname").should("include", "/services/");
            cy.get(".access-type").contains("a", "Access the service", { matchCase: false }).click({ force: true });
            cy.contains("a", "Access instructions").should("be.visible");
            cy.contains("Next").first().click({ force: true });
            cy.location("pathname").should("include", "/summary");
            cy.get("#customizable_project_item_project_id").select(project.name);
            cy.checkCaptcha();
            cy.get("button.btn-primary").contains("Pin!", { matchCase: false }).first().click();
            cy.getCookie("resources").then((cookie) => {
              let resources: IResource[] = [];
              if (!!cookie) {
                resources = JSON.parse(cookie.value);
              }

              cy.scrapResourceDetails().then((resource) => {
                resources.push(resource);
                cy.setCookie("resources", JSON.stringify(resources), {
                  domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, ""),
                });
                expect(resource.projectName).to.be.equal(project.name);
              });
            });
          });
      });
  });

  // Run when fully open access will be availableMP_JIRA_URL
  xit("Add fully open access", () => {});
  xit("Add other", () => {});
  it("Add order required", () => {
    cy.visit("/");
    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            cy.loginAs(user, true);
            cy.visit("/services");

            cy.get('select[name="order_type"]').select("order_required");
            cy.location("search").should("include", "order_type=order_required");
            cy.get(".service-box").first().find("h2").find("a").click();
            cy.location("pathname").should("include", "/services/");
            cy.get(".access-type").contains("a", "Access the service", { matchCase: false }).click({ force: true });
            cy.contains("a", "Access instructions").should("be.visible");
            cy.contains("Next").first().click();
            cy.location("pathname").should("include", "/summary");
            cy.get("#customizable_project_item_project_id").select(project.name);
            cy.checkCaptcha();
            cy.get("button.btn-primary").contains("Send access request", { matchCase: false }).first().click();
            cy.getCookie("resources").then((cookie) => {
              let resources: IResource[] = [];
              if (!!cookie) {
                resources = JSON.parse(cookie.value);
              }

              cy.scrapResourceDetails().then((resource) => {
                resources.push(resource);
                cy.setCookie("resources", JSON.stringify(resources), {
                  domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, ""),
                });
                expect(resource.projectName).to.be.equal(project.name);
              });
            });
          });
      });
  });
  xit("Should create epic in JIRA on new project", () => {
    cy.jiraLogin();
    cy.visit(Cypress.env("MP_JIRA_URL") + "/projects/EOSCSOPR/issues");
    cy.waitUntil(() => Cypress.$(".loading").length === 0);

    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            const epicName = "Project, " + user.last_name + " " + user.first_name + ", " + project.name;
            cy.jiraFindTicketBy("name", epicName).click();
            cy.waitUntil(() => Cypress.$(".loading").length === 0);

            cy.jiraGetTicketDetailFrom("priority").should("include.text", "Low");
            cy.jiraGetTicketDetailFrom("status").should("include.text", "Active");
            cy.jiraGetTicketDetailFrom("resolution").should("include.text", "Unresolved");
            cy.jiraGetTicketDetailFrom("epic name").should("include.text", project.name);
            cy.jiraGetTicketDetailFrom("ci-displayName").should("include.text", user.last_name + " " + user.first_name);
            cy.jiraGetTicketDetailFrom("ci-name").should("include.text", user.last_name);
            cy.jiraGetTicketDetailFrom("ci-surname").should("include.text", user.first_name);
            cy.jiraGetTicketDetailFrom("ci-email").should("include.text", project.email);
            cy.jiraGetTicketDetailFrom("ci-institution").should("include.text", project.organization);
            cy.jiraGetTicketDetailFrom("ci-department").should("include.text", project.department);
            cy.jiraGetTicketDetailFrom("ci-departmentalWebPage").should("include.text", project.webpage);
            cy.jiraGetTicketDetailFrom("cp-customerTypology").should(
              "include.text",
              project.customerTypology.toLowerCase(),
            );
            cy.jiraGetTicketDetailFrom("so-projectName").should("include.text", project.name);
            cy.jiraGetTicketDetailFrom("cp-collaborationCountry").should("include.text", "N/A");
            cy.jiraGetTicketDetailFrom("cp-customerCountry").should(
              "include.text",
              Utilities.capitalizeAll(project.countryOfOrigin),
            );
            project.scientificDomains.forEach((scientificDomain) => {
              cy.jiraGetTicketDetailFrom("cp-scientificDiscipline").should(
                "include.text",
                Utilities.capitalizeAll(scientificDomain),
              );
            });
            cy.jiraGetTicketDetailFrom("eosc-hub test").should("include.text", "No");

            cy.jiraGetResources().then((jiraResources) => {
              cy.getCookie("resources").then((cookie) => {
                if (!cookie) {
                  return;
                }

                const getStatusBy = (accessType: accessType) => {
                  switch (accessType) {
                    case "open access":
                      return "ready";
                    case "order required":
                      return "new";
                    default:
                      return "new";
                  }
                };
                const appResources: IJiraResource[] = (JSON.parse(cookie.value) as IResource[]).map((resource) => ({
                  name: "Services order, " + user.last_name + " " + user.first_name + "," + resource.name.toUpperCase(),
                  status: getStatusBy(resource.accessType.toLowerCase() as any),
                }));

                appResources.forEach((resource) => {
                  expect(jiraResources.some((jiraResource) => (jiraResource.name = resource.name))).to.be.equal(true);
                });
              });
            });
          });
      });
  });
});

describe("Offers messages", { tags: "@extended-test" }, () => {
  // tag: @extended-test
  it("Should setup cookies", () => {
    const user = UserFactory.create();
    cy.clearCookie("user");
    cy.setCookie("user", JSON.stringify(user), { domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, "") });
    cy.setCookie("user", JSON.stringify(user), { domain: Cypress.config().baseUrl.replace(/(^\w+:|^)\/\//, "") });

    const project = ProjectFactory.create();
    cy.clearCookie("project");
    cy.setCookie("project", JSON.stringify(project), {
      domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, ""),
    });
    cy.setCookie("project", JSON.stringify(project), { domain: Cypress.config().baseUrl.replace(/(^\w+:|^)\/\//, "") });
  });
  it("Should send message to project support", () => {
    cy.visit("/");
    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            cy.loginAs(user, true);
            project.name += "_second";
            cy.visit("/projects/new");
            cy.fillFormProject(project);
            cy.contains("button", "Create new project").click();

            cy.get(".services-menu")
              .contains("a", "contact with eosc experts", { matchCase: false })
              .click({ force: true });

            const message = Utilities.getRandomString();
            cy.setCookie("message", message, { domain: Cypress.env("MP_JIRA_URL").replace(/(^\w+:|^)\/\//, "") });
            cy.get("#message_message").type(message);
            cy.get(".btn-primary").contains("Send message", { matchCase: false }).click();
            cy.get(".frame").contains(message).should("exist");
          });
      });
  });
  xit("Message should be visible in JIRA", () => {
    cy.jiraLogin();
    cy.visit(Cypress.env("MP_JIRA_URL") + "/projects/EOSCSOPR/issues");
    cy.waitUntil(() => Cypress.$(".loading").length === 0);

    cy.getCookie("user")
      .then((user) => JSON.parse(user.value) as IUser)
      .then((user) => {
        cy.getCookie("project")
          .then((project) => JSON.parse(project.value) as IProject)
          .then((project) => {
            const epicName = "Project, " + user.last_name + " " + user.first_name + ", " + project.name;
            cy.jiraFindTicketBy("name", epicName).click();
            cy.waitUntil(() => Cypress.$(".loading").length === 0);

            cy.getCookie("message").then((message) => {
              cy.get("#issue_actions_container").find(".action-body").contains(message.value);
            });
          });
      });
  });
  xit("Should send message from JIRA to app", () => {});
});
