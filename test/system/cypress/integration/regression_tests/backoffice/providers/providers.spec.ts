import { ProvidersFactory } from "../../../../factories/provider.factory";
import { UserFactory } from "../../../../factories/user.factory";

describe("Providers", () => {
  const user = UserFactory.create({ roles: ["service_portfolio_manager"] });
  const [provider, provider2, provider3, provider4] = [...Array(4)].map(() =>
    ProvidersFactory.create()
  );

  const correctLogo = "logo.jpg";
  const wrongLogo = "logo.tif";

  beforeEach(() => {
    cy.visit("/");
  });

  it("should go to Providers in Backoffice and select one of providers", () => {
    cy.loginAs(user);
    cy.get("[data-e2e='my-eosc-button']")
      .click();
    cy.get("[data-e2e='backoffice']")
      .click();
    cy.location("href")
      .should("contain", "/backoffice");
    cy.get("[data-e2e='providers']")
      .click();
    cy.location("href")
      .should("contain", "/backoffice/providers");
    cy.get("[data-e2e='backoffice-providers-list'] a")
      .eq(0)
        .click();
    cy.contains("a", "Edit")
      .should("be.visible");
    cy.contains("a", "Delete")
      .should("be.visible");
  });

  it("should add new provider and find in filter and autocomplete in front and backoffice", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='add-new-provider']")
      .click();
    cy.location("href")
      .should("contain", "/providers/new");
    cy.fillFormCreateProvider(provider, correctLogo);
    cy.get("[data-e2e='create-provider-btn']")
      .click();
    cy.contains(
      "div.alert-success",
      "New provider created successfully")
      .should("be.visible");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[data-e2e='more-link-providers']")
          .click();
        cy.contains("a", value)
          .click();
        cy.contains("h2", value)
          .should("be.visible");
        cy.contains("div", "Manage the provider")
          .should("be.visible");
        cy.get("[data-e2e='btn-browse-resource']")
          .click();
        cy.location("href")
          .should("include", "/services?providers=");
        cy.get("[data-e2e='filter-tag']")
          .should("be.visible");
        cy.get("[data-e2e='searchbar-input']")
          .type(value);
        cy.get("[data-e2e='autocomplete-results'] li")
          .contains("Provider")
          .next()
          .contains(value)
          .click();
        cy.location("href")
          .should("contain", "/providers/");
        cy.contains("h2", value)
          .should("be.visible");

        cy.visit("/backoffice/services");
        cy.get("#collapse_providers [data-e2e='multicheckbox-search']").
          type(value);
        cy.get("[data-e2e='filter-checkbox']")
          .next()
          .contains(value)
          .parent()
          .click();
        cy.get("[data-e2e='filter-tag']")
          .should("be.visible");
        cy.get("[data-e2e='searchbar-input']")
          .type(value);
        cy.get("[data-e2e='autocomplete-results'] li")
          .contains("Provider")
          .next()
          .contains(value)
          .click();
        cy.location("href")
          .should("contain", "/backoffice/providers/");
        cy.contains("h1", value)
          .should("be.visible");
      });
  });

  it("shouldn't add new provider", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='add-new-provider']")
      .click();
    cy.location("href")
      .should("contain", "/providers/new");
    cy.fillFormCreateProvider(provider2, wrongLogo);
    cy.get("[data-e2e='create-provider-btn']")
      .click();
    cy.get("div.invalid-feedback")
      .should("be.visible");
    cy.contains(
      "div.invalid-feedback",
      "Logo is not a valid file format and Logo format you're trying to attach is not supported. " +
      "Supported formats: png, gif, jpg, jpeg, pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon")
      .should("be.visible");
  });

  it("should deleted provider without resource and find only in filter and autocomplete in backoffice", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='add-new-provider']")
      .click();
    cy.location("href")
      .should("contain", "/providers/new");
    cy.fillFormCreateProvider(provider3, correctLogo);
    cy.get("[data-e2e='create-provider-btn']")
      .click();
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.contains("a", "Delete")
          .click();
        cy.contains("div.alert-success", "Provider has been removed")
          .should("be.visible");
        cy.visit("/");
        cy.get("a[data-e2e='more-link-providers']")
          .click();
        cy.contains("a", value)
          .should("not.exist");
        cy.get("[data-e2e='searchbar-input']").
          type(value, { force: true });
        cy.contains("[data-e2e='autocomplete-results'] li", "Provider")
          .should("not.exist");

        cy.visit("/backoffice/services");
        cy.get("#collapse_providers [data-e2e='multicheckbox-search']")
          .type(value);
        cy.get("[data-e2e='filter-checkbox']")
          .next()
          .contains(value)
          .parent()
          .click();
        cy.get("[data-e2e='filter-tag']")
          .should("be.visible");
        cy.get("[data-e2e='searchbar-input']")
          .type(value);
        cy.get("[data-e2e='autocomplete-results'] li")
          .contains("Provider")
          .next()
          .contains(value)
          .click();
        cy.location("href")
          .should("contain", "/backoffice/providers/");
        cy.contains("h1", value)
          .should("be.visible");
        cy.contains("a", "Edit")
          .should("not.exist");
        cy.contains("a", "Delete")
          .should("not.exist");
      });
  });

  it("should go to Providers in Backoffice and edit one of providers", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='backoffice-providers-list'] a")
      .eq(3)
      .parent()
      .find("a")
      .contains("Edit")
      .click();
    cy.fillFormCreateProvider(
      {
        ...provider4,
        basicName: "Edited provider",
        adminFirstName: "test",
        adminLastName: "test",
        adminEmail: "test@mail.pl",
      },
      correctLogo
    );
    cy.get("[data-e2e='create-provider-btn']")
      .click();
    cy.get(".alert-success")
      .contains("Provider updated correctly")
      .should("be.visible");
    cy.contains("h1", "Edited provider")
      .should("be.visible");
  });
});
