import { Controller } from "@hotwired/stimulus";
import Highcharts from "highcharts";
import maps from "highcharts/modules/map";
maps(Highcharts);

import europe from "@highcharts/map-collection/custom/europe.geo.json";
import world from "@highcharts/map-collection/custom/world.geo.json";

export default class extends Controller {
  static targets = [];

  connect() {
    this.generateChart(this.element);
  }

  generateChart(element) {
    const region = element.dataset.region;
    var map = this.returnRegion(region);

    let width = 250;
    if ("about" === element.dataset.type) {
      width = 840;
    }

    let height = 223;
    if ("about" === element.dataset.type) {
      height = 420;
    }

    Highcharts.mapChart(element, {
      chart: {
        map: map,
        height: height,
        width: width,
      },
      title: {
        text: "",
      },
      mapNavigation: {
        enabled: true,
        enableDoubleClickZoomTo: true,
      },
      legend: {
        enabled: false,
      },
      series: [
        {
          name: "Country",
          data: JSON.parse(element.dataset.geographical_availabilities),
          dataLabels: {
            enabled: false,
          },
          tooltip: {
            headerFormat: "",
            pointFormat: "{point.name}",
            outside: false,
          },
        },
      ],
    });
  }

  returnRegion(geographical_availabilities) {
    if (geographical_availabilities.indexOf("WW") > -1) {
      return world;
    } else {
      return europe;
    }
  }
}
