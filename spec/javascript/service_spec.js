import { Application } from "stimulus";
import ServiceController from "service_controller";

const showUrl = (element, value, eventType) => {
  const event = new Event(eventType);
  element.value = value;
  element.dispatchEvent(event);
};

describe("ServiceController", () => {
  describe("#showConnectedUrl", () => {

    beforeEach(() => {
      document.body.innerHTML =
        '<div data-controller="service">' +
        '<select id="select" data-target="service.serviceType"' +
        'data-action="change->service#showConnectedUrl" >' +
        '<option value=""></option>' +
        '<option value="open_access">open_access</option>' +
        '<option value="catalog">catalog</option>' +
        '</select>' +
        '<div id="result" data-target="service.connectedUrl" class="hidden-fields"> </div>' +
        '</div>';

      const application = Application.start();
      application.register("service", ServiceController);
    })

    it("Show connected url", () => {
      select = document.getElementById("select")
      result = document.getElementById("result")

      showUrl(select, 'open_access', 'change')

      expect(result.classList).not.toContain("hidden-fields")
    });
  });
});
