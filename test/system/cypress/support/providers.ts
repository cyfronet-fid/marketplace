/**
 * Define new commands types for typescript (for autocompletion)
 */
 import { IProviders } from "../factories/provider.factory";

 declare global {
   namespace Cypress {
     interface Chainable {
      
       fillFormCreateProvider(provider: Partial<IProviders>, logo:any): Cypress.Chainable<void>;
 
     }
   }
 }
 
 const selectItem = (provider: string[], selector: string) => {
   cy.get(selector).then(($el) => {
     $el
       .find(".choices__item--selectable")
       .find(".choices__button")
       .each((index, $btn) => $btn.click());
   });
 
   if (provider && provider.length > 0) {
    provider.forEach((el) => {
       cy.get(selector)
         .find('.choices__input[type="search"]')
         .type(el)
         .type("{enter}");
       cy.get(selector)
         .find(".choices__item.choices__item--selectable")
         .contains(el)
         .should("exist");
     });
   }
 };
 
 Cypress.Commands.add("fillFormCreateProvider", (provider: IProviders, logo) => {
   cy.get("#basic-header")
     .click();
 
   if (provider.basicName) {
     cy.get("#provider_name")
       .clear({ force: true })
       .type(provider.basicName);
   }
 
   if (provider.basicAbbreviation) {
     cy.get("#provider_abbreviation")
       .clear({ force: true })
       .type(provider.basicName);
   }
 
   if (provider.basicWebpage_url) {
     cy.get("#provider_website")
       .clear({ force: true })
       .type(provider.basicWebpage_url);
   }
 
   cy.get("#marketing-header")
     .click();
 
   if (provider.marketingDescription) {
     cy.get("#provider_description")
       .clear()
       .type(provider.marketingDescription);
   }

   cy.get("#provider_logo")
     .attachFile(logo);
 
   if (provider.marketingMultimedia) {
     cy.get("#provider_multimedia_0")
       .clear()
       .type(provider.marketingMultimedia);
   }
 
   cy.get("#classification-header").click();
 
   selectItem(provider.classificationScientificDomains,".provider_scientific_domains");
 
   cy.get("body")
     .type("{esc}");
 
   if (provider.classificationTag) {
     cy.get("#provider_tag_list_0")
       .clear()
       .type(provider.classificationTag);
    }

   cy.get("#location-header")
     .click()

     if (provider.locationStreet) {
      cy.get("#provider_street_name_and_number")
        .clear({ force: true })
        .type(provider.locationStreet);
    }
  
    if (provider.locationPostCode) {
      cy.get("#provider_postal_code")
        .clear({ force: true })
        .type(provider.locationPostCode);
    }
  
    if (provider.locationCity) {
      cy.get("#provider_city")
        .clear({ force: true })
        .type(provider.locationCity);
    }
  
    if (provider.locationCountry) {
      cy.get("#provider_country")
        .select(provider.locationCountry);
    }
 
   cy.get("#contact-header")
     .click();
 
   if (provider.contactFirstname) {
     cy.get("#provider_main_contact_attributes_first_name")
       .clear({ force: true })
       .type(provider.contactFirstname);
   }
 
   if (provider.contactLastname) {
     cy.get("#provider_main_contact_attributes_last_name")
       .clear({ force: true })
       .type(provider.contactLastname);
   }
 
   if (provider.contactEmail) {
     cy.get("#provider_main_contact_attributes_email")
       .clear({ force: true })
       .type(provider.contactEmail);
   }
 
   if (provider.publicContactsEmail) {
     cy.get("#provider_public_contacts_attributes_0_email")
       .clear({ force: true })
       .type(provider.publicContactsEmail);
   }

   cy.get("#admins-header")
     .click();

    if (provider.adminFirstName) {
      cy.get("#provider_data_administrators_attributes_0_first_name")
        .clear({ force: true })
        .type(provider.adminFirstName);
    }
  
    if (provider.adminLastName) {
      cy.get("#provider_data_administrators_attributes_0_last_name")
        .clear({ force: true })
        .type(provider.adminLastName);
    }
  
    if (provider.adminEmail) {
      cy.get("#provider_data_administrators_attributes_0_email")
        .clear({ force: true })
        .type(provider.adminEmail);
    }
 });