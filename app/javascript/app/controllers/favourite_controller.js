import { Controller } from 'stimulus'
import Rails from '@rails/ujs'

export default class extends Controller {
    static targets = ["checkbox", "result"]

    connect() {
        this.updateCheckboxLabels();
    }

    async updateFromRes() {
        // TODO: check if list empty and show modal
        const response = await this.sendRequest(this.updateFavourites());
        const result = await this.getResponse(response);
        this.updateCheckboxLabels();
    }

    async updateFromFav() {
        // TODO: check if list empty and show modal
        const response = await this.sendRequest(this.updateFavourites());
        const result = await this.getResponse(response);
        this.updateResults()
        this.updateCheckboxLabels();
    }

    async sendRequest(data) {
        const rawResponse = await fetch("/favourites/services", {
            method: "POST",
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "X-CSRF-Token": Rails.csrfToken(),
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
            },
            body: data
        });
        console.log(rawResponse)
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

    updateResults() {
        this.resultTarget.remove();
    }

    updateCheckboxLabels() {
        const elements = this.checkboxTargets;
        for (const element of elements) {
            if (element.checked) {
                element.nextElementSibling.innerText = "Remove from favourites"
            } else {
                element.nextElementSibling.innerText = "Add to favourites"
            }
        }
    }

    updateFavourites() {
        const elements = this.checkboxTargets;
        for (const element of elements) {
            return new URLSearchParams({
                'favourite': event.currentTarget.getAttribute("value"),
                'update': element.checked
            })
        }
    }
}
