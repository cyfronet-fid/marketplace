import "./sort_filter";
import initBadgeState from "./badge";
import initSorting from "./sort_filter";
import initFlash from "./flash";
import initChoices from "./choices";
import initCookiesPolicy from "./cookies_policy";
import "bootstrap/dist/js/bootstrap";
import "./nav";

require("@rails/ujs").start();
require("@rails/activestorage").start();
require("shepherd.js");

import { library, dom } from "@fortawesome/fontawesome-svg-core";
import { far } from "@fortawesome/free-regular-svg-icons";
import { fas } from "@fortawesome/free-solid-svg-icons";
import "@fortawesome/fontawesome-free/js/all";
import "@fortawesome/fontawesome-free/css/all.css";
import "bootstrap-datepicker";
import Cookies from "js-cookie/src/js.cookie";
import Shepherd from "shepherd.js";

window.Shepherd = Shepherd;

window.Cookies = Cookies;

// :TODO: for now import all fonts, so ux people can work without problems, optimize later
library.add(fas, far);

import initProbes from "./user_action";
import assignTabIdToWindow from "./tabs";
import { handleTourFor } from "./tours";
import initMasonry from "./masonry";

document.addEventListener("turbo:before-render", function (event) {
  initSorting(event.data.newBody);
  dom.watch();
});

document.addEventListener("turbo:load", async function (event) {
  initChoices();
  initCookiesPolicy();
  initBadgeState();
  initMasonry();
  console.log("TEST UPDATE 1");
  await initProbes();
});

document.addEventListener("ajax:success", function (event) {
  initChoices();
});

document.addEventListener("MP:modalLoaded", function (event) {
  initChoices();
});

document.addEventListener("MP:tourEvent", function (event) {
  handleTourFor(event);
});

/**
 * Apart from turbolinks we need to replace FA for the first page load
 */
document.addEventListener("DOMContentLoaded", function (event) {
  dom.i2svg();
  initSorting();
  initFlash();
  initBadgeState();
  assignTabIdToWindow();
  dom.watch();
});

window.addEventListener("beforeunload", () => {
  window.sessionStorage.tabId = window.tabId;
  return null;
});

require("trix");
require("@rails/actiontext");
require("highcharts");
require("@highcharts/map-collection/custom/world.geo.json");
require("@highcharts/map-collection/custom/europe.geo.json");
