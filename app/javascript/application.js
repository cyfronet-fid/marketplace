// Entry point for the build script in your package.json
// if (process.env.CUSTOMIZATION_PATH) {
//   // try catch is to handle situation where there is no /javascript/images in customization path
//   try {
//     require(process.env.CUSTOMIZATION_PATH + "/javascript/images");
//   } catch (e) {}
// }

import "./app";
import "./controllers";

import jquery from "jquery";
import "@hotwired/turbo-rails";

window.$ = window.jQuery = jquery;
