import { Application } from "stimulus";
import OfferController from "offer_controller";

const showUrl = (element, value, eventType) => {
  const event = new Event(eventType);
  element.value = value;
  element.dispatchEvent(event);
};

describe("OfferController", () => {
  describe("#showWebpage", () => {
    beforeEach(() => {
      document.body.innerHTML = '<div id="result" data-target="offer.webpage"> </div>';

      //     '<div data-controller="offer">' +
      //     '<select id="select" data-target="offer.offerType"' +
      //     'data-action="change->offer#showWebpage" >' +
      //     '<option value=""></option>' +
      //     '<option value="open_access">open_access</option>' +
      //     '<option value="external">external</option>' +
      //     '</select>' +
      //     '<input class="form-check-input is-valid boolean optional" data-target="offer.external?"' +
      //     'data-action="change->offer#showWebpage" type="checkbox"' +
      //     'value="1" name="offer[external]" id="offer_external">' +
      //     '<div id="result" data-target="offer.webpage" class="hidden-fields"> </div>' +
      //     '<div class="offer-attributes" data-target="offer.attributes"> </div>'+
      //     '</div>';
      //
      const application = Application.start();
      application.register("offer", OfferController);
    });

    it("Show connected url", () => {
      // select = document.getElementById("select")
      result = document.getElementById("result");

      // showUrl(select, 'open_access', 'change')

      expect(result.classList).not.toContain("hidden-fields");
    });
  });
});
