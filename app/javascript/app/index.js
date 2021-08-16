import "app/sort_filter"
import initBadgeState from "app/badge";
import initSorting from "app/sort_filter";
import initFlash from "app/flash";
import initChoices from "app/choices";
import initCookiesPolicy from "app/cookies_policy";
import 'bootstrap/dist/js/bootstrap';
import 'stylesheets/application';
import "app/nav";

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("shepherd.js")

import { library, dom } from '@fortawesome/fontawesome-svg-core';
import { far } from '@fortawesome/free-regular-svg-icons';
import { fas } from '@fortawesome/free-solid-svg-icons';
import "@fortawesome/fontawesome-free/js/all";
import "@fortawesome/fontawesome-free/css/all.css";
import 'bootstrap-datepicker';
import Shepherd from 'shepherd.js';
window.Shepherd = Shepherd;

import Cookies from 'js-cookie/src/js.cookie';
window.Cookies = Cookies;

// :TODO: for now import all fonts, so ux people can work without problems, optimize later
library.add(fas, far);

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import initProbes from "./user_action";
import assignTabIdToWindow from "./tabs";
import redirect_to_login from "./autologin";

const application = Application.start();
const context = require.context("./controllers", true, /.js$/);
application.load(definitionsFromContext(context));

document.addEventListener("turbolinks:before-render", function(event) {
    dom.i2svg({
        node: event.data.newBody
    });
    initSorting(event.data.newBody);
    dom.watch();
});

document.addEventListener("turbolinks:load", async function (event) {
    initChoices();
    initCookiesPolicy();
    initBadgeState();
    await initProbes();
});

document.addEventListener("ajax:success", function(event) {
    initChoices();
});

/**
 * Apart from turbolinks we need to replace FA for the first page load
 */
document.addEventListener('DOMContentLoaded', function (event) {
    dom.i2svg();
    redirect_to_login();
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


require("trix")
require("@rails/actiontext")
require("highcharts")
require('@highcharts/map-collection/custom/world.geo.json');
require('@highcharts/map-collection/custom/europe.geo.json');

