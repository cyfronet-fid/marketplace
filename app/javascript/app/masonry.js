import Masonry from "masonry-layout";

export default function initMasonry() {
  var grid = document.querySelector(".details-box-wrapper");
  var msnry = new Masonry(grid, {
    // options...
    itemSelector: ".details-box",
    percentPosition: true,
    gutter: 24,
  });
}
