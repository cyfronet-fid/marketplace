import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ['categorySelect', 'form', 'selected', 'type'];

    connect() {
        this.SERVICES_URL = this.data.get("servicesPath");
        this.CATEGORIES_URL = this.data.get("categoriesPath");
        this.PROVIDERS_URL = this.data.get("providersPath");

        this.categorySelectTarget.value = "";
        let match = window.location.pathname.match(new RegExp(`^.*${this.CATEGORIES_URL}/([^/]+$)`));
        if(match !== null)
            this.categorySelectTarget.value = match[1];

        this.refresh();
    }

    refresh() {
        let actionURL = this.SERVICES_URL;

        if (this.categorySelectTarget.value !== "")
            actionURL = `${this.CATEGORIES_URL}/${this.categorySelectTarget.value}`;
        if (this.typeTarget.value === "provider")
            actionURL = this.PROVIDERS_URL;

        this.selectedTarget.innerHTML = this.getSelectedText();
        this.formTarget.setAttribute("action", actionURL);
    }

    getSelectedText() {
        return this.categorySelectTarget
          .options[this.categorySelectTarget.selectedIndex].text;

    }
}
