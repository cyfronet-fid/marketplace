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
import TC from "@rolemodel/turbo-confirm";

window.$ = window.jQuery = jquery;

TC.start({
  activeClass: "d-flex",
  contentSlots: {
    body: {
      contentAttribute: "confirm-details",
      slotSelector: "#confirm-body",
    },
    acceptText: {
      contentAttribute: "confirm-button",
      slotSelector: "#confirm-accept",
    },
    rejectText: {
      contentAttribute: "confirm-cancel",
      slotSelector: "#dismiss-btn",
    },
  },
});
