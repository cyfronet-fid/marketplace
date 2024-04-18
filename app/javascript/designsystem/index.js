require("@rails/activestorage").start();

import "bootstrap/dist/js/bootstrap";
// import "stylesheets/designsystem";

import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

import { library, dom } from "@fortawesome/fontawesome-svg-core";
import { far } from "@fortawesome/free-regular-svg-icons";
import { fas } from "@fortawesome/free-solid-svg-icons";

library.add(fas, far);

document.addEventListener("turbo:before-render", function (event) {
  dom.i2svg({ node: event.data.newBody });
  dom.watch();
});

/**
 * Apart from turbolinks we need to replace FA for the first page load
 */
document.addEventListener("DOMContentLoaded", function () {
  dom.i2svg();
  dom.watch();
});
