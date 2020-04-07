import "app/sort_filter"
import initSorting from "app/sort_filter";
import initFlash from "app/flash";
import initChoises from "app/choises";
import initCookiesPolicy from "app/cookies_policy";
import 'bootstrap/dist/js/bootstrap';
import 'stylesheets/application';
import "app/nav";

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()

import { library, dom } from '@fortawesome/fontawesome-svg-core';
import { far } from '@fortawesome/free-regular-svg-icons';
import { fas } from '@fortawesome/free-solid-svg-icons';
import 'bootstrap-datepicker';

// :TODO: for now import all fonts, so ux people can work without problems, optimize later
library.add(fas, far);

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

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

document.addEventListener("turbolinks:load", function(event) {
    initChoises();
    initCookiesPolicy();
});

document.addEventListener("ajax:success", function(event) {
    initChoises();
});

/**
 * Apart from turbolinks we need to replace FA for the first page load
 */
document.addEventListener('DOMContentLoaded', function () {
    dom.i2svg();
    initSorting();
    initFlash();
    dom.watch();
});

require("trix")
require("@rails/actiontext")
require("highcharts")
require('@highcharts/map-collection/custom/world.geo.json');
require('@highcharts/map-collection/custom/europe.geo.json');

