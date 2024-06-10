import { Controller } from "@hotwired/stimulus";
import Rails from "@rails/ujs";
import { post } from "@rails/request.js";

export default class extends Controller {
  static targets = ["checkbox", "result", "popup", "serviceBox", "backlink"];

  connect() {
    this.updateCheckboxLabels();
  }

  async updateFromRes(event) {
    const response = await this.sendRequest(this.updateFavourites(event));
    const result = await this.getResponse(response);
    this.updateCheckboxLabels();
  }

  async updateFromFav(event) {
    const response = await this.sendRequest(this.updateFavourites(event));
    const result = await this.getResponse(response);
    this.updateResults(event);
    this.updateCheckboxLabels();
    // this.showEmptyList(result);
  }

  async sendRequest(data) {
    console.log(data);
    const rawResponse = await post("/favourites/services", {
      body: data,
      responseKind: "turbo-stream",
    });
    return rawResponse;
  }

  async getResponse(response) {
    try {
      return await response;
    } catch (e) {
      if (e instanceof SyntaxError) {
        response.data = [];
        response.html = "";
        return response;
      } else {
        console.log(e);
      }
    }
  }

  updateResults(event) {
    const serviceBox = document.getElementById(event.target.dataset.value);
    serviceBox.remove();
  }

  updateCheckboxLabels() {
    const elements = this.checkboxTargets;
    for (const element of elements) {
      if (element.checked) {
        element.nextElementSibling.innerText = "Remove from favourites";
      } else {
        element.nextElementSibling.innerText = "Add to favourites";
      }
    }
  }

  updateFavourites(event) {
    return {
      favourite: event.currentTarget.getAttribute("value"),
      update: event.currentTarget.checked,
    };
  }
}
