import { VocabularyFactory } from "cypress/factories/vocabulary.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { VocabularyMessages } from "../../../../fixtures/messages";

describe("Vocabularies", () => {
  const user = UserFactory.create({ roles: ["service_portfolio_manager"] });
  const [vocabulary, vocabulary1, vocabulary2] = [...Array(3)].map(() => VocabularyFactory.create());
  const message = VocabularyMessages;

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  it("should create new vocabularies without parent", () => {
    cy.openUserDropdown();
    cy.get("[data-e2e='backoffice']").click();
    cy.location("href").should("contain", "/backoffice");
    cy.get("[data-e2e='other_settings']").click();
    cy.location("href").should("contain", "backoffice/other_settings");
    cy.get("[data-e2e='vocabularies']").click();
    cy.location("href").should("contain", "/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='add-new-vocabulary-btn']").click();
    cy.location("href").should("contain", "/new");
    cy.fillFormCreateVocabulary(vocabulary);
    cy.get("[data-e2e='create-vocabulary-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
  });

  it("should create new vocabularies with parent", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='add-new-vocabulary-btn']").click();
    cy.location("href").should("contain", "/new");
    cy.fillFormCreateVocabulary({ ...vocabulary1, parent: "Research communities" });
    cy.get("[data-e2e='create-vocabulary-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
  });

  it("shouldn't create new vocabularies", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='add-new-vocabulary-btn']").click();
    cy.get("[data-e2e='create-vocabulary-btn']").click();
    cy.contains("div.invalid-feedback", message.alertNameValidation).should("be.visible");
  });

  it("should edit vocabularies", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='backoffice-vocabulary-list'] li")
      .contains("Researchers")
      .parent()
      .find("a")
      .contains("Edit")
      .click();
    cy.fillFormCreateVocabulary({ ...vocabulary, name: "Edited vocabulary" });
    cy.get("[data-e2e='create-vocabulary-btn']").click();
    cy.contains("div.alert-success", message.successUpdationMessage).should("be.visible");
  });

  it("shouldn't delete vocabulary with successors connected to it", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='backoffice-vocabulary-list'] li").contains("Businesses").parent().find("a.delete-icon").click();
    cy.get("#confirm-accept").click();
    cy.contains(".alert-danger", message.alertDeletionMessageSuccessors).should("be.visible");
  });

  it("shouldn't delete scientific domain with services connected to it", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='backoffice-vocabulary-list'] li").contains("Providers").parent().find("a.delete-icon").click();
    cy.get("#confirm-accept").click();
    cy.contains(".alert-danger", message.alertDeletionMessageResource).should("be.visible");
  });

  it("should delete vocabulary without services", () => {
    cy.visit("/backoffice/other_settings/vocabularies");
    cy.get("[data-e2e='add-new-vocabulary-btn']").click();
    cy.fillFormCreateVocabulary(vocabulary2);
    cy.get("[data-e2e='create-vocabulary-btn']").click();
    cy.location("pathname").should("not.contain", "new");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/backoffice/other_settings/vocabularies");
        cy.contains(value).parent().find("a.delete-icon").click();
        cy.get("#confirm-accept").click();
        cy.contains(".alert-success", message.successDeletionMessage).should("be.visible");
      });
  });
});
