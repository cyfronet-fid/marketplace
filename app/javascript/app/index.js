import "./sort_filter";
import initBadgeState from "./badge";
import initSorting from "./sort_filter";
import initChoices from "./choices";
import initCookiesPolicy from "./cookies_policy";
import "bootstrap/dist/js/bootstrap";
import "./nav";

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

document.addEventListener("turbo:before-stream-render", function (event) {
  if (event.hasOwnProperty("data")) {
    initSorting(event.data.newBody);
  }
  initChoices();
  dom.watch();
});

document.addEventListener("turbo:load", async function (event) {
  initChoices();
  initCookiesPolicy();
  initBadgeState();
  initMasonry();
  await initProbes();
  // This is a hack for a correct behavior of dropdown menu, hope we'll migrate to the newer bootstrap version
  const menu = document.getElementById("main-menu");

  if (menu) {
    menu.addEventListener("click", (e) => {
      e.stopPropagation();
      const target = e.target;
      const navLinks = menu.getElementsByClassName("nav-link");
      const tabs = menu.getElementsByClassName("tab-pane");
      let removeActive = (e) => {
        e.classList.remove("active");
      };
      const tab = this.getElementById(target.dataset.target);
      if (tab) {
        Array.from(navLinks).forEach((e) => removeActive(e));
        target.classList.add("active");
        Array.from(tabs).forEach((e) => removeActive(e));
        tab.classList.add("active");
      }
    });
  }
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

window.addEventListener("beforeunload", () => {
  window.sessionStorage.tabId = window.tabId;
  return null;
});

require("trix");
require("@rails/actiontext");
require("highcharts");
require("@highcharts/map-collection/custom/world.geo.json");
require("@highcharts/map-collection/custom/europe.geo.json");
