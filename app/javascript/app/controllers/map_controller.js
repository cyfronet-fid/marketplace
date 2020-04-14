import { Controller } from "stimulus"
import Highcharts from "highcharts"
import maps from 'highcharts/modules/map'
maps(Highcharts)

import europe from "@highcharts/map-collection/custom/europe.geo.json"
import world from "@highcharts/map-collection/custom/world.geo.json"

export default class extends Controller {
  static targets = [];

  connect() {
    this.generateChart(this.element);
  }

  generateChart(element) {

    const region = element.dataset.region;
    var map = this.returnRegion(region);


    Highcharts.mapChart(element, {
      chart: {
        map: map,
        height: "100%",
        width: '223'
      },
      title: {
        text: ''
      },
      legend: {
        enabled: false
      },
      series: [{
        name: 'Country',
        data: JSON.parse(element.dataset.places),
        dataLabels: {
          enabled: false
        },
        tooltip: {
          headerFormat: '',
          pointFormat: '{point.name}'
        }
      }]
    })
  }

  returnRegion(places) {
    if(places.indexOf("WW") > -1) {
      return world
    }
    else if(places.indexOf("EU") > -1) {
      return europe
    }
    else {
      return europe
    }
  }
}
