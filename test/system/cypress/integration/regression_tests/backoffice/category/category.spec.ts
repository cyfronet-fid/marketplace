import { CategoryFactory } from "cypress/factories/category.factory";
import { UserFactory } from "../../../../factories/user.factory";

describe("Category", () => {
  const user = UserFactory.create({roles: ["service_portfolio_manager"]});
  const [category, category1, category2, category3,category4] = [...Array(5)].map(()=> CategoryFactory.create())

  const correctLogo = "logo.jpg"
  const wrongLogo = "logo.tif"

  beforeEach(() => {
    cy.visit("/");
  });
  
  it("should create new category without parent", () => {
    cy.loginAs(user);
    cy.get("[data-e2e='my-eosc-button']")
      .click();
    cy.get("[data-e2e='backoffice']")
      .click();
    cy.location("href")
      .should("contain", "/backoffice");
    cy.get("[data-e2e='categories']")
      .click();
    cy.location("href")
      .should("contain", "backoffice/categories");
    cy.get("[data-e2e='add-new-category']")   
      .click();
    cy.fillFormCreateCategory(category, correctLogo);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.get("h1")
      .invoke("text")
      .then(value=>{
        cy.location("href")
          .should("contain", `/backoffice/categories/${value}`);
        cy.visit("/")
        cy.get("li")
          .contains("Categories")
          .click();
        cy.get("a[href*='categories'][data-e2e='branch-link']")
          .contains(value)
          .click();
        cy.location("href")
          .should("contain", `/services/c/${value}`)
    });
  });

  it("should create new category with parent", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories/new")
    cy.fillFormCreateCategory({...category1, parent: "Sharing & Discovery"}, correctLogo);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.get("h1")
      .invoke("text")
      .then(value=>{
        cy.location("href")
          .should("contain", `/backoffice/categories/${value}`);
        cy.visit("/services")
        cy.get("[data-e2e='categories-list'] a").contains("Sharing & Discovery").click()
        cy.location("href")
          .should("contain", `services/c/sharing-discovery`);
        cy.get("[data-e2e='sub-categories-list']").should("be.visible").find("li").contains(value).click()
        cy.location("href")
          .should("contain", `services/c/${value}`);  
    });
  });

  it("should add new category without logo", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories/new")
    cy.fillFormCreateCategory(category2, false);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.get("h1")
      .invoke("text")
      .then(value=>{
        cy.location("href")
          .should("contain", `/backoffice/categories/${value}`);
        cy.visit("/")
        cy.get("li")
          .contains("Categories")
          .click();
        cy.get("a[href*='categories'][data-e2e='branch-link']")
          .contains(value)
          .click();
        cy.location("href")
          .should("contain", `/services/c/${value}`);
    });
  });

  it("shouldn't create new category", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories/new")
    cy.fillFormCreateCategory({...category3, name:""}, wrongLogo);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.contains("div.invalid-feedback", "Logo is not a valid file format and Logo format you're trying to attach is not supported")
      .should("be.visible");
    cy.contains("div.invalid-feedback", "Name can't be blank")
      .should("be.visible");
  });

  it("shouldn't delete category with resources connected to it", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories");
    cy.get("[data-e2e='backoffice-categories-list'] li")
      .eq(0)
      .find("a.delete-icon")
      .click();
    cy.get(".alert-danger")
      .contains("This category has successors connected to it, therefore is not possible to remove it. If you want to remove it, edit them so they are not associated with this category anymore")
      .should("be.visible");
  });

  it("should delete category without resources", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories/new");
    cy.fillFormCreateCategory(category4, correctLogo);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.get("h1")
      .invoke("text")
      .then(value=>{
        cy.visit("/backoffice/categories");
        cy.contains(value)
          .parent()
          .find("a.delete-icon")
          .click();
        cy.get(".alert-success")
          .contains("Category removed")
          .should("be.visible");
    });
  })

  it("should edit category", () => {
    cy.loginAs(user);
    cy.visit("/backoffice/categories")
    cy.get(".list-group.backoffice-list li")
      .eq(0)
      .find("a")
      .contains("Edit")
      .click();
    cy.fillFormCreateCategory({...category, name:"Edited category"}, false);
    cy.get("[data-e2e='create-category-btn']")
      .click();
    cy.get(".alert-success")
    .contains("Category updated correctly")
    .should("be.visible");   
  });
});