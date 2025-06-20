import { defineConfig } from "cypress";

export default defineConfig({
  defaultCommandTimeout: 25000,
  pageLoadTimeout: 100000,
  responseTimeout: 100000,
  viewportWidth: 1400,
  viewportHeight: 1200,
  fileServerFolder: "./",
  chromeWebSecurity: false,
  retries: {
    runMode: 1,
    openMode: 1,
  },
  watchForFileChanges: false,
  video: false,
  env: {
    debug: false,
    FAIL_FAST_ENABLED: true,
  },
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents(on, config) {
      return require("./cypress/plugins/index.js")(on, config);
    },
    baseUrl: "http://localhost:5000",
    specPattern: "cypress/e2e/**/*.spec.ts",
  },
});
