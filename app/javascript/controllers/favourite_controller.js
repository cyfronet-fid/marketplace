import { Controller } from "@hotwired/stimulus";
import Rails from "@rails/ujs";

export default class extends Controller {
  static targets = ["checkbox", "result", "popup", "serviceBox", "backlink"];

  connect() {
    this.updateCheckboxLabels();
  }

  async updateFromRes(event) {
    const response = await this.sendRequest(this.updateFavourites());
    const result = await this.getResponse(response);
    this.updateCheckboxLabels();
    this.showPopup(result);
  }

  async updateFromFav(event) {
    const response = await this.sendRequest(this.updateFavourites());
    const result = await this.getResponse(response);
    this.updateResults(event);
    this.updateCheckboxLabels();
    this.showEmptyList(result);
  }

  async sendRequest(data) {
    const rawResponse = await fetch("/favourites/services", {
      method: "POST",
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": Rails.csrfToken(),
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: data,
    });
    return rawResponse;
  }

  async getResponse(response) {
    try {
      return await response.json();
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

  updateFavourites() {
    return new URLSearchParams({
      favourite: event.currentTarget.getAttribute("value"),
      update: event.currentTarget.checked,
    });
  }

  showPopup(result) {
    if (result.html.length > 0 && result.type === "modal") {
      this.popupTarget.innerHTML = result.html;
      $("#popup-modal").modal("show");
    }
  }

  showEmptyList(result) {
    if (result.html.length > 0 && result.type === "empty_box") {
      this.serviceBoxTarget.innerHTML = result.html;
      this.backlinkTarget.classList.add("d-none");
      this.backlinkTarget.classList.remove("d-block");
    }
  }
}
