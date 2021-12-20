// ***********************************************************
// This example support/index.js is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

/**
 * Libs
 */
require('cypress-terminal-report/src/installLogsCollector')();
import '@cypress/skip-test/support';
import 'cypress-promise/register';
import 'cypress-wait-until';
import 'cypress-file-upload';
import "cypress-fail-fast";





/**
 * Custom commands
 */
import './auth';
import './coverage';
import './utilities';

import './jira';
import './offers';
import './resources';
import './category';
import './scientific-domain';
import './providers';
import './platforms'

/**
 * Don't fail on uncaught exception
 */
Cypress.on('uncaught:exception', (err, runnable) => false);

beforeEach(() => {
  // hide cookie policy box
  cy.setCookie('cookieconsent_status', 'dismiss')
  cy.setCookie('tours-marketplace-services-show-service_about_intro', "later")
  cy.setCookie('tours-marketplace-profiles-show-intro', "later")
});
