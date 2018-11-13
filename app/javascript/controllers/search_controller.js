import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ['categorySelect', 'form'];
    SERVICES_URL = "/services";
    CATEGORIES_URL = "/categories";

    initialize() {
    }

    connect() {
        this.categorySelectTarget.value = "";
        let match = window.location.pathname.match(new RegExp(`^${this.CATEGORIES_URL}/(\\d+$)`));
        if(match !== null)
            this.categorySelectTarget.value = match[1];

        this.refresh();
    }

    refresh() {
        let actionURL = this.SERVICES_URL;

        if(this.categorySelectTarget.value !== "")
            actionURL = `${this.CATEGORIES_URL}/${this.categorySelectTarget.value}`;

        this.formTarget.setAttribute("action", actionURL);
    }
}
