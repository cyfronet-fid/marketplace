import { Controller } from 'stimulus'
import Rails from '@rails/ujs'

export default class extends Controller {
    static targets = ["checkbox", "clear", "bar", "box"]

    connect() {
        if (this.checkboxTargets) {
            this.updateCheckboxLabels();
        }
    }

    async update() {
        const response = await this.sendRequest();
        const result = await this.getResponse(response);
        this.updateServicesBox(result.html);
        this.toggleDisabled(result.data.length);
        this.uncheckRemoved(result.data);
        this.updateCheckboxLabels();
        if (result.data.length > 0) {
            this.loadBottomBar();
        } else {
            this.hideBottomBar();
        }
    }

    async sendRequest() {
        const data = "comparison=" + event.currentTarget.getAttribute("value");
        const rawResponse = await fetch("/comparisons/services", {
            method: "POST",
            headers: {
              "X-Requested-With": "XMLHttpRequest",
              "X-CSRF-Token": Rails.csrfToken(),
              "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
            },
            body: data
        });
        return rawResponse;
    }

    updateServicesBox(response) {
        this.boxTarget.innerHTML = response;
    }

    updateCheckboxLabels() {
        const elements = this.checkboxTargets;
        for (const element of elements) {
            if (element.checked) {
                element.nextElementSibling.innerText = "Added"
            } else {
                element.nextElementSibling.innerText = "Add to compare"
            }
        }
    }

    clearAll() {
        this.uncheckRemoved([]);
        this.toggleDisabled(0);
        this.hideBottomBar();
        this.updateCheckboxLabels();
    }

    loadBottomBar() {
        const bar = this.barTarget;
        bar.classList.remove("d-none");
        bar.classList.add("d-block");
    }

    hideBottomBar() {
        const bar = this.barTarget;
        bar.classList.add("d-none");
        bar.classList.remove("d-block");
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

    uncheckRemoved(active) {
        const elements = this.checkboxTargets;
        for (const element of elements) {
            if (!active.includes(element.value)) {
                element.checked = false;
            }
        }
    }

    toggleDisabled(counter) {
        const elements = this.checkboxTargets;
        if (counter > 2) {
            for(const element of elements) {
                if (!element.checked) {
                    console.log(element);
                    element.disabled = true;
                    element.parentNode.setAttribute("data-toggle", "tooltip");
                    element.parentNode.setAttribute("data-delay", '{ "show": 0, "hide": 5000 }');
                    element.parentNode.setAttribute("data-trigger", "click");
                    element.parentNode.setAttribute("title", "You have reached the maximum number of items you can compare");

                }
            }
        } else {
            for(const element of elements) {
                element.disabled = false;
                element.parentNode.removeAttribute("data-toggle");
                element.parentNode.removeAttribute("title");
            }
        }
    }
}