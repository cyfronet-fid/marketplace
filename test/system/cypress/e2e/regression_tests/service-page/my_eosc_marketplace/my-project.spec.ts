import { UserFactory } from "../../../../factories/user.factory";
import { ProjectFactory } from "../../../../factories/project.factory";

describe("My project", () => {
  const user = UserFactory.create();
  const [project, project2, project3] = [...Array(3)].map(() => ProjectFactory.create());

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  const openAccessResource = "DisVis";

  it.skip("should add new project, pin a service and add review", () => {
    cy.visit("/projects");
    cy.location("pathname").should("equal", "/projects");
    cy.get('a[data-e2e="go-to-create-project-form-btn"]').click();
    cy.location("pathname").should("equal", "/projects/new");
    cy.fillFormProject(project);
    cy.get("[data-e2e='create-project-btn']").click();
    cy.location("href").should("contain", "/projects/");
    cy.contains("a", "Project details").should("be.visible");
    cy.contains("a", "Resources").click();
    cy.contains("a", "Add your first service").click();
    cy.get("[data-e2e='searchbar-input']").type(openAccessResource);
    cy.get("[data-e2e='query-submit-btn']").click();
    cy.get('[data-e2e="service-name"]').contains(openAccessResource).click();

    cy.location("href").should("contain", "/services/");
    cy.get('[data-e2e="access-service-btn"]').click();
    cy.contains("a", "Pin to a project").click();
    cy.location("href").should("contain", "/summary");
    cy.checkCaptcha();
    cy.contains("button", "Pin!").click();
    cy.contains(".alert-success", "Offer pinned successfully").should("be.visible");
    cy.location("href").should("match", /(\/projects\/.*\/services)/);
    cy.contains("a", "Details").click();
    cy.refreshUntilVisible('[data-e2e="review-service-btn"]');
    cy.get('[data-e2e="review-service-btn"]').as("review-btn").should("be.visible");
    cy.get("@review-btn").click();
    cy.location("href").should("contain", "/opinion/new");
    cy.get("[data-rating-stars='service_opinion_service_rating']").find(".list-inline-item").eq(2).click();
    cy.get("[data-rating-stars='service_opinion_order_rating']").find(".list-inline-item").eq(3).click();
    cy.get("[data-e2e='send-review-btn']").click();
    cy.contains(".alert-success", "Rating submitted successfully").should("be.visible");
    cy.contains("a", openAccessResource).click();
    cy.location("href").should("contain", `/services/${openAccessResource.toLocaleLowerCase()}`);
    cy.contains("a", "Reviews (1)").click();
    cy.get("#opinions").should("be.visible");
  });

  it("should edit project", () => {
    cy.visit("/projects");
    cy.get('a[data-e2e="go-to-create-project-form-btn"]').click();
    cy.fillFormProject(project2);
    cy.get("[data-e2e='create-project-btn']").click();
    cy.contains("a", "Edit").click();
    cy.fillFormProject({ name: "Edited project" });
    cy.get("[data-e2e='update-project-btn']").click();
    cy.contains("h1", "Edited project").should("be.visible");
    cy.contains(".alert-success", "Project updated successfully").should("be.visible");
  });

  it("should delete project", () => {
    cy.visit("/projects");
    cy.get('a[data-e2e="go-to-create-project-form-btn"]').click();
    cy.fillFormProject(project3);
    cy.get("[data-e2e='create-project-btn']").click();
    cy.contains("a", "Delete").click();
    cy.get("[id='confirm-accept").click();
    cy.contains(".alert-success", "Project removed successfully").should("be.visible");
  });
});
