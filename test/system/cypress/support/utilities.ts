export class Utilities {
  public static getUUID4(): string {
    function replace(char) {
      const randomValue = (Math.random() * 16) | 0;
      const replacedValue = char == "x" ? randomValue : (randomValue & 0x3) | 0x8;
      return replacedValue.toString(16);
    }
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, replace);
  }

  public static getRandomNumber() {
    return Math.floor(Math.random() * 9000000000) + 1000000000;
  }

  public static getRandomString(length: number = 32): string {
    const CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    const CHARS_SIZE = CHARS.length > length ? length : CHARS.length;
    return [...Array(CHARS_SIZE)]
      .map(() => {
        const charIndex = Math.floor(Math.random() * CHARS_SIZE);
        return CHARS.charAt(charIndex);
      })
      .join("");
  }

  public static getRandomEmail() {
    return Utilities.getRandomString(6).toLowerCase() + "@domain.com";
  }

  public static getRandomUrl(protocol: string = "http://") {
    return protocol + Utilities.getRandomString(8).toLowerCase() + "." + Utilities.getRandomString(3).toLowerCase();
  }

  public static capitalizeAll(sentence: string) {
    return sentence
      .toLowerCase()
      .split(" ")
      .map((word) => word.charAt(0).toUpperCase() + word.substring(1))
      .join(" ");
  }
}

/**
 * Define new commands types for typescript (for autocompletion)
 */
declare global {
  namespace Cypress {
    interface Chainable {
      /**
       * Check if element exists in body without failing test
       */
      hasInBody(selector: string): Cypress.Chainable<boolean>;

      /**
       * Hack: Force visit different origin URL
       */
      forceVisit(url: string): Cypress.Chainable<void>;

      /**
       * Captcha
       */
      checkCaptcha(nr?: number): Cypress.Chainable<void>;

      /**
       * Hack: Get multiple aliases values
       */
      getAll(...aliases: string[]): Cypress.Chainable<{ [alias: string]: string | number | null }>;

      refreshUntilVisible(selector: string): Cypress.Chainable<boolean>;
      /**
       * Refresh page until element be visible
       */
    }
  }
}

Cypress.Commands.add("hasInBody", (selector) => cy.get("body").then((body) => body.find(selector).length > 0));
Cypress.Commands.add("forceVisit", (url) => {
  cy.window().then((win) => {
    return win.open(url, "_self");
  });
});

Cypress.Commands.add("checkCaptcha", (nr = 0) => {
  cy.wait(500);
  cy.get("iframe")
    .eq(nr)
    .its("0.contentDocument.body")
    .should("not.be.undefined")
    .and("not.be.empty")
    .then(cy.wrap)
    .find("#recaptcha-anchor")
    .should("be.visible")
    .click();
  cy.wait(1000);
});

Cypress.Commands.add("getAll", (...aliases: string[]) => {
  const results = {};
  aliases.forEach((alias) => cy.get(alias).then((aliasValue) => (results[alias.replace("@", "")] = aliasValue)));
  return cy.wrap(results);
});

Cypress.Commands.add("refreshUntilVisible", (selector: string) => {
  const el = Cypress.$(selector);
  for (let attempt = 0; attempt < 10; attempt++) {
    if (attempt === 10 || el.length >= 1) {
      return;
    } else {
      if (el.length === 0) {
        cy.reload();
      }
    }
  }
});
