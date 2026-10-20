// Staging environment of the EOSC commons of eosc.pl (eosc-pl-common) for
// the pl discovery hub and the pl marketplace instance.
// lib/versions/deploy-hubs.sh copies this file to env/ of the checkout and
// the JSON files next to it to configurations/, then commons.Dockerfile
// replaces the placeholders __DISCOVERY_HUB_URL__ and __MARKETPLACE_URL__
// with the URLs of the hub and of the marketplace instance (build arguments)
// and runs `gulp build --production --env env/env.staging.js`.
// The structure follows env/env.beta.js of the repository; the breakpoints,
// the auto-login domains and the to-top label come from its development
// configuration files, which hold no links. The ordering system and Onedata
// have no staging instance, their production URLs stay.
const mainHeaderConfig = require("../configurations/main-header.staging.config.json");
const mainFooterConfig = require("../configurations/main-footer.staging.config.json");
const totopWrapperConfig = require("../configurations/totop-wrapper.development.json");
const defaultConfiguration = require("../configurations/configuration.development.json");

export const discoveryhubUrl = "__DISCOVERY_HUB_URL__";
export const marketplaceUrl = "__MARKETPLACE_URL__";
export const bosUrl = "https://bos.eosc.pl";
export const onedataUrl = "https://data.eosc.pl"; // keep: the components can use it with a different config

export const environment = {
  mainHeaderConfig,
  mainFooterConfig,
  defaultConfiguration,
  totopWrapperConfig,
  production: false,
  showDemoBadge: true,
  windowTagName: "eosccommon",
  customUserTabs: [
    {
      id: "Provider",
      name: "Provider",
      links: [
        {
          caption: "Become provider",
          href: `${discoveryhubUrl}/#become-provider`,
          dividerAfter: true
        },
        {
          caption: "Documentation",
          href: `${discoveryhubUrl}/documentation`
        }
      ]
    }
  ],
  customProviderTabs: [
    {
      id: "provider",
      name: "Provider",
      links: [
        {
          caption: "Backoffice",
          href: `${marketplaceUrl}/backoffice/services`
        },
        {
          caption: "Ordering system",
          href: `${bosUrl}`,
          dividerAfter: true
        },
        {
          caption: "+ Add new service",
          href: `${marketplaceUrl}/backoffice/services/new`
        },
        {
          caption: "+ Add new provider",
          href: `${marketplaceUrl}/backoffice/providers/new`
        },
        {
          caption: "+ Add new catalogue",
          href: `${marketplaceUrl}/backoffice/catalogues/new`,
          dividerAfter: true
        },
        {
          caption: "Documentation",
          href: `${discoveryhubUrl}/documentation`
        }
      ]
    }
  ]
};

if (!window[environment.windowTagName]) {
  window[environment.windowTagName] = {};
}
