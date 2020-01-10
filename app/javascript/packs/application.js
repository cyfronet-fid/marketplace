/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import 'bootstrap/dist/js/bootstrap';
import 'stylesheets/application';

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
import "./sort_filter"
import initSorting from "./sort_filter";
import initFlash from "./flash";
import initChoises from "./choises";
import initCookiesPolicy from "./cookies_policy";


const application = Application.start();
const context = require.context("controllers", true, /.js$/);
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
