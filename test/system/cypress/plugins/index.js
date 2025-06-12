/// <reference types="cypress" />
// ***********************************************************
// This example plugins/index.js can be used to load plugins
//
// You can change the location of this file or turn off loading
// the plugins file with the 'pluginsFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/plugins-guide
// ***********************************************************

/**
 * @type {Cypress.PluginConfig}
 */
module.exports = (on, config) => {
  if (config.env["debug"]) {
    console.log("!!!!!!!!!!!!! You're running cypress in debug mode !!!!!!!!!!!!");
  }

  /**
   * Show full console log on test fail
   */
  require("cypress-terminal-report/src/installLogsPrinter")(on, {
    printLogsToConsole: !!config.env["debug"] ? "always" : "onFail",
  });

  on("before:browser:launch", (browser = {}, launchOptions) => {
    /**
     * Chrome memory & security optimizations
     */
    if (browser.name === "chrome") {
      /**
       * Disable same origin policy
       */
      launchOptions.args.push("--disable-web-security");

      /**
       * Enable tracing bugs inside iframes
       */
      launchOptions.args.push("--disable-site-isolation-trials");

      /**
       * Increase chrome tab memory limit
       * By default 512MB on 32-bit systems or 1.4GB on 64-bit systems
       */
      launchOptions.args.push("--max_old_space_size=1024");

      /**
       * Increase chrome shared memory space from 64MB to unlimited (since Chrome 65)
       */
      launchOptions.args.push("--disable-dev-shm-usage");
      return launchOptions;
    }
  });

  require("cypress-fail-fast/plugin")(on, config);
  return config;
};
