import { ProvidersFactory, ProvidersFactoryExtended } from "../../../../factories/provider.factory";
import { UserFactory } from "../../../../factories/user.factory";
import { ProviderMessages } from "../../../../fixtures/messages";

describe("Providers", () => {
  const user = UserFactory.create({ roles: ["coordinator"] });
  const [provider, provider2, provider3] = [...Array(3)].map(() => ProvidersFactory.create());
  const [providerExtented] = [...Array(1)].map(() => ProvidersFactoryExtended.create());
  const message = ProviderMessages;

  const correctLogo = "logo.jpg";
  const wrongLogo = "logo.svg";

  const providerStatusDraft = "LifeWatch ERIC";
  const providerWithResourceDeleted = "D4Science Infrastructure";
  const providerWithResourceDraft = "European Space Agency (ESA)";
  const providerWithResourcePublished = "EUDAT";
  const providerWithResourceErrored = "CSC";
  const resourceProviderForPublishedResource = "Interuniversity consortium CIRMMP";

  beforeEach(() => {
    cy.visit("/");
    cy.loginAs(user);
  });

  it("should go to Providers in Backoffice and select one of providers", { tags: "@extended-test" }, () => {
    cy.openUserDropdown();
    cy.get("[data-e2e='provider-panel']").click();
    cy.get("[data-e2e='backoffice']").click();
    cy.location("href").should("contain", "/backoffice");
    cy.get("[data-e2e='providers']").click();
    cy.location("href").should("contain", "/backoffice/providers");
    cy.get("[data-e2e='backoffice-providers-list'] a.provider-name").eq(0).click();
    cy.contains("a", "Edit").should("be.visible");
    cy.contains("a", "Delete").should("be.visible");
  });

  it.skip("should add new provider and find in filter and autocomplete in front and backoffice", () => {
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='add-new-provider']").click();
    cy.location("href").should("contain", "/providers/new");
    cy.fillFormCreateProvider(provider, correctLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[data-e2e='more-link-providers']").click();
        cy.contains("a", value).click();
        cy.contains("h2", value).should("be.visible");
        cy.get("[data-e2e='btn-browse-service']").click();
        cy.location("href").should("include", "/services?providers=");
        cy.get("[data-e2e='filter-tag']").should("be.visible");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='autocomplete-results'] li").contains("Provider").next().contains(value).click();
        cy.location("href").should("contain", "/providers/");
        cy.contains("h2", value).should("be.visible");

        cy.visit("/backoffice/services");
        cy.get("#collapse_providers [data-e2e='multicheckbox-search']").type(value);
        cy.get("[data-e2e='filter-checkbox']").next().contains(value).parent().click();
        cy.get("[data-e2e='filter-tag']").should("be.visible");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='autocomplete-results'] li").contains("Provider").next().contains(value).click();
        cy.location("href").should("contain", "/backoffice/providers/");
        cy.contains("h1", value).should("be.visible");
      });
  });

  it.skip("shouldn't add new provider", () => {
    cy.visit("/backoffice/providers/new");
    cy.location("href").should("contain", "/providers/new");
    cy.fillFormCreateProvider({ ...provider, basicWebpage_url: "wrongFormat", adminEmail: "wrongFormat" }, wrongLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.contains("div.invalid-feedback", message.alertLogoValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertUrlValidation).should("be.visible");
    cy.contains("div.invalid-feedback", message.alertEmailValidation).should("be.visible");
  });

  it.skip("should deleted provider without service and find only in filter and autocomplete in backoffice", () => {
    cy.visit("/backoffice/providers/new");
    cy.location("href").should("contain", "/providers/new");
    cy.fillFormCreateProvider(provider2, correctLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.location("href").should("not.contain", "/providers/new");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.contains("a", "Delete").click();
        cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
        cy.visit("/");
        cy.get("a[data-e2e='more-link-providers']").click();
        cy.contains("a", value).should("not.exist");
        cy.get("[data-e2e='searchbar-input']").type(value, { force: true });
        cy.contains("[data-e2e='autocomplete-results'] li", "Provider").should("not.exist");

        cy.visit("/backoffice/services");
        cy.get("#collapse_providers [data-e2e='multicheckbox-search']").type(value);
        cy.get("[data-e2e='filter-checkbox']").next().contains(value).parent().click();
        cy.get("[data-e2e='filter-tag']").should("be.visible");
        cy.get("[data-e2e='searchbar-input']").type(value);
        cy.get("[data-e2e='autocomplete-results'] li").contains("Provider").next().contains(value).click();
        cy.location("href").should("contain", "/backoffice/providers/");
        cy.contains("h1", value).should("be.visible");
        cy.contains("a", "Edit").should("not.exist");
        cy.contains("a", "Delete").should("not.exist");
      });
  });

  it("should delete provider with services with deleted status", () => {
    cy.visit("/backoffice/providers");
    cy.contains("a", providerWithResourceDeleted).parents("li.providers").find("a.kebab-link svg").click();
    cy.get(".dropdown-menu.show").find("[data-e2e='delete-menu']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });

  it("should delete provider with services with draft status", () => {
    cy.visit("/backoffice/providers");
    cy.contains("a", providerWithResourceDraft).parents("li.providers").find("a.kebab-link svg").click();
    cy.get(".dropdown-menu.show").find("[data-e2e='delete-menu']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });

  it("should delete provider with services with published status", () => {
    cy.visit("/backoffice/providers");
    cy.contains("a", providerWithResourcePublished).parents("li.providers").find("a.kebab-link svg").click();
    cy.get(".dropdown-menu.show").find("[data-e2e='delete-menu']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });

  it("should delete provider with services with errored status", () => {
    cy.visit("/backoffice/providers");
    cy.contains("a", providerWithResourceErrored).parents("li.providers").find("a.kebab-link svg").click();
    cy.get(".dropdown-menu.show").find("[data-e2e='delete-menu']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });

  it("should delete provider which is services provider for published resources", () => {
    cy.visit("/backoffice/providers");
    cy.contains("a", resourceProviderForPublishedResource).parents("li.providers").find("a.kebab-link svg").click();
    cy.get(".dropdown-menu.show").find("[data-e2e='delete-menu']").click();
    cy.get("[data-e2e='confirm-accept']").click();
    cy.contains("div.alert-success", message.successDeletionMessage).should("be.visible");
  });

  it.skip("should go to Providers in Backoffice and edit one of providers", () => {
    cy.visit("/backoffice/providers/new");
    cy.fillFormCreateProvider(provider3, correctLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.contains("a", "Edit").click();
    cy.fillFormCreateProvider({ basicName: "Edited provider" }, correctLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.contains(".alert-success", message.successUpdationMessage).should("be.visible");
    cy.contains("h1", "Edited provider").should("be.visible");
  });

  it.skip("should check if draft provider is visible only in Backoffice", () => {
    cy.get("a[data-e2e='more-link-providers']").click();
    cy.contains("a", providerStatusDraft).should("not.exist");
    cy.visit("/services");
    cy.get("[data-e2e='searchbar-input']").type(providerStatusDraft);
    cy.get("[data-e2e='autocomplete-results'] li").should("not.have.text", providerStatusDraft);
    cy.get("#collapse_providers [data-e2e='multicheckbox-search']").type(providerStatusDraft);
    cy.get("#collapse_providers li").contains(providerStatusDraft).should("not.exist");

    cy.visit("/backoffice/services");
    cy.get("#collapse_providers [data-e2e='multicheckbox-search']").type(providerStatusDraft);
    cy.get("[data-e2e='filter-checkbox']").next().contains(providerStatusDraft).parent().click();
    cy.get("[data-e2e='filter-tag']").should("be.visible");
    cy.get("[data-e2e='service-id'] span").should("have.text", "draft");
    cy.get("[data-e2e='searchbar-input']").type(providerStatusDraft);
    cy.get("[data-e2e='autocomplete-results'] li").contains("Provider").next().contains(providerStatusDraft).click();
    cy.location("href").should("contain", "/backoffice/providers/");
    cy.contains("h1", providerStatusDraft).should("be.visible");
  });

  it("should go to Backoffice and create provider by filling in all fields", { tags: "@extended-test" }, () => {
    cy.visit("/backoffice/providers");
    cy.get("[data-e2e='add-new-provider']").click();
    cy.location("href").should("contain", "/providers/new");
    cy.fillFormCreateProvider(providerExtented, correctLogo);
    cy.get("[data-e2e='create-provider-btn']").click();
    cy.contains("div.alert-success", message.successCreationMessage).should("be.visible");
    cy.get("h1")
      .invoke("text")
      .then((value) => {
        cy.visit("/");
        cy.get("a[data-e2e='more-link-providers']").click();
        cy.contains("a", value).click();
        cy.contains("h2", value).should("be.visible");
        cy.get("[data-e2e='provider-details-btn']").click();
        cy.hasProviderDetails();
        cy.intercept("/providers/*").as("providerPage");
        cy.get("[data-e2e='provider-about-btn']").click();
        cy.hasProviderAbout();
        cy.wait("@providerPage");
        cy.get("a[data-e2e='tag-btn']").should("be.visible").click();
        cy.location("href").should("contain", "/services?tag=");
        cy.get("[data-e2e='filter-tag']").should("be.visible");
      });
  });
});
