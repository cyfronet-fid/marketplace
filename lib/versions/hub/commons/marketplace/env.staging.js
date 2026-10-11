// Staging environment of the EOSC commons of the EOSC portal
// (eosc-portal-common) for the marketplace discovery hub and the marketplace
// instance: search-18 and marketplace-18. lib/versions/deploy-hubs.sh copies
// this file to env/ of the checkout and the JSON file next to it to
// configurations/, then commons.Dockerfile runs
// `gulp build --production --env env/env.staging.js`.
// The structure follows env/env.beta.js of the repository; the footer links,
// the breakpoints and the auto-login domains come from its development
// configuration files, which hold no link to a hub or a marketplace. The
// user dashboard has no staging instance, the sandbox URL stays.
const mainHeaderConfig = require("../configurations/main-header.staging.config.json");
const mainFooterConfig = require("../configurations/main-footer.development.config.json");
const defaultConfiguration = require("../configurations/configuration.development.json");

const environment = {
  mainHeaderConfig,
  mainFooterConfig,
  defaultConfiguration,
  marketplaceUrl: "https://marketplace-18.docker-fid.grid.cyf-kr.edu.pl",
  dashboardUrl: "https://my.sandbox.eosc-beyond.eu",
  production: false,
  windowTagName: "eosccommon",
};
exports.environment = environment;

if (!window[environment.windowTagName]) {
  window[environment.windowTagName] = {};
}
