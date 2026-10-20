import { Controller } from "@hotwired/stimulus";
import * as Turbo from "@hotwired/turbo";

export default class extends Controller {
  next(event) {
    if (event.detail.success) {
      const fetchResponse = event.detail.fetchResponse;

      history.pushState({ turbo_frame_history: true }, "", fetchResponse.response.url);

      Turbo.visit(fetchResponse.response.url);
    }
  }

  goToSummary(event) {
    event.preventDefault();
    document.getElementById("dismiss-btn").click();
    document.getElementById("summary-button").click();
  }
}
