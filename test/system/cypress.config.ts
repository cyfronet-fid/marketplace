import { defineConfig } from "cypress";

export default defineConfig({
  defaultCommandTimeout: 20000,
  pageLoadTimeout: 50000,
  responseTimeout: 50000,
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
    FAIL_FAST_ENABLED: false,
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
