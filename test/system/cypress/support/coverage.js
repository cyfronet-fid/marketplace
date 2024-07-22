// ***********************************************
// This example commands.js shows you how to
// create the custom commands: 'createDefaultTodos'
// and 'createTodo'.
//
// The commands.js file is a great place to
// modify existing commands and create custom
// commands for use throughout your tests.
//
// You can read more about custom commands here:
// https://on.cypress.io/commands
// ***********************************************

import { finder } from "@medv/finder";

before(() => {
  window.testedSelectors = [];
});

after(() => {
  const selectors = Cypress._.uniq(window.testedSelectors);
  const win = cy.state("window");

  selectors.forEach((selector) => {
    const el = win.document.querySelector(selector);

    if (el) {
      el.style.opacity = 1;
      el.style.border = "1px solid magenta";
    }
  });
});

const getSelector = ($el) => {
  if ($el.attr("data-cy")) {
    return `[data-cy=${$el.attr("data-cy")}]`;
  }

  // Skip iframes due to error with captcha
  // return finder($el[0], {
  //     // a trick to point "finder" at the application's iframe
  //     root: cy.state('window').document.body,
  // })
};

const rememberSelector = ($el) => {
  const selector = getSelector($el);

  window.testedSelectors.push(selector);
};

Cypress.Commands.overwrite("type", function (type, $el, text, options) {
  rememberSelector($el);

  return type($el, text, options);
});

Cypress.Commands.overwrite("check", function (check, $el, options) {
  rememberSelector($el);

  return check($el, options);
});

Cypress.Commands.overwrite("click", function (click, $el, options) {
  rememberSelector($el);

  return click($el, options);
});
