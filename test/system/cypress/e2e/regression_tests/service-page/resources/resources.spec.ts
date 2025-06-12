import { UserFactory } from "../../../../factories/user.factory";
import { ProjectFactory } from "../../../../factories/project.factory";

describe("Resources", () => {
  const user = UserFactory.create();
  const [project, project2] = [...Array(5)].map(() => ProjectFactory.create());

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  const openAccessResource = "AMBER";
  const orderRequiredResourceInternal = "B2ACCESS";
  const resourceWithFewOffer = "B2DROP";

  it("should pin open access offer to a project only once", () => {
    cy.get("[data-e2e='searchbar-input']").type(openAccessResource).type("{enter}");
    cy.get('[data-e2e="service-name"]').contains(openAccessResource).click();

    cy.location("href").should("contain", "/services/");
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.location("href").should("contain", `/services/${openAccessResource.toLocaleLowerCase()}/information`);
    cy.contains("a", "Pin to a project").click();
    cy.location("href").should("contain", `/services/${openAccessResource.toLocaleLowerCase()}/summary`);
    cy.get("[data-e2e='add-new-project-btn']").click();
    cy.fillFormProject(project);
    // cy.checkCaptcha(1);
    cy.contains("input", "Create new project").click();
    cy.contains("h3", "Project details").should("be.visible");
    cy.contains("button", "Pin!").click();
    cy.contains("h1", openAccessResource).should("be.visible");
    cy.location("href").should("match", /(\/projects\/.*\/services)/);
    cy.contains(".alert-success", "Offer pinned successfully").should("be.visible");

    cy.visit("/projects");
    cy.contains("a", "Add resource to this project").click();
    cy.get("[data-e2e='searchbar-input']").type(openAccessResource).type("{enter}");
    cy.get('[data-e2e="service-name"]').contains(openAccessResource).click();
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.contains("a", "Pin to a project").click();
    cy.location("href").should("contain", "/summary");
    // cy.checkCaptcha();
    cy.contains("button", "Pin!").click();
    cy.contains("div", "Project already pinned with this offer").should("be.visible");
  });

  it("should order order required internal offer many times", () => {
    cy.get("[data-e2e='searchbar-input']").type(orderRequiredResourceInternal).type("{enter}");
    cy.get('[data-e2e="service-name"]').contains(orderRequiredResourceInternal).click();

    cy.location("href").should("contain", "/services/");
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.contains("a", "Final details").click();
    cy.location("href").should("contain", "/summary");
    cy.get("[data-e2e='add-new-project-btn']").click();
    cy.fillFormProject(project2);
    // cy.checkCaptcha(1);
    cy.contains("input", "Create new project").click();
    cy.contains("h3", "Project details").should("be.visible");
    cy.contains("button", "Send access request").click();
    cy.contains("h1", orderRequiredResourceInternal).should("be.visible");
    cy.location("href").should("match", /(\/projects\/.*\/services)/);
    cy.contains(".alert-success", "Offer ordered successfully").should("be.visible");

    cy.visit("/projects");
    cy.contains("a", "Add resource to this project").click();
    cy.get("[data-e2e='searchbar-input']").type(orderRequiredResourceInternal);
    cy.get("[data-e2e='query-submit-btn']").click();
    cy.get('[data-e2e="service-name"]').contains(orderRequiredResourceInternal).click();
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.contains("a", "Final details").click();
    cy.location("href").should("contain", "/summary");
    // cy.checkCaptcha();
    cy.contains("button", "Send access request").click();
    cy.contains(".alert-success", "Offer ordered successfully").should("be.visible");
  });

  it("should add service with few offers", () => {
    cy.get("[data-e2e='searchbar-input']").type(resourceWithFewOffer).type("{enter}");
    cy.get('[data-e2e="service-name"]').contains(resourceWithFewOffer).click();

    cy.location("href").should("contain", "/services/");
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.location("href").should("contain", `/services/${resourceWithFewOffer.toLocaleLowerCase()}/offers`);
    cy.get("div.unchecked").eq(0).should("contain", "Select an offer").click();
    cy.get("div.checked").eq(0).should("contain", "Selected offer").should("be.visible");
    cy.contains("a", "Access instructions").click();
    cy.location("href").should("contain", `/services/${resourceWithFewOffer.toLocaleLowerCase()}/information`);
    cy.contains("a", "Configuration").click();
    cy.location("href").should("contain", `/services/${resourceWithFewOffer.toLocaleLowerCase()}/configuration`);
    cy.get("#parameter_id1").type("1");
    cy.contains("a", "Final details").click();
    cy.location("href").should("contain", `/services/${resourceWithFewOffer.toLocaleLowerCase()}/summary`);
    cy.get("[data-e2e='add-new-project-btn']").click();
    cy.fillFormProject(project2);
    // cy.checkCaptcha(1);
    cy.get("input[name='commit']").click("bottom");
    cy.contains("h3", "Project details").should("be.visible");
    cy.contains("button", "Send access request").click();
    cy.contains("h1", resourceWithFewOffer).should("be.visible");
    cy.location("href").should("match", /(\/projects\/.*\/services)/);
    cy.contains(".alert-success", "Offer ordered successfully").should("be.visible");
  });
});
