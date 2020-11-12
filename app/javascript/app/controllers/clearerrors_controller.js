import {Controller} from 'stimulus'

export default class extends Controller {
    connect() {
    }

    initialize() {
    }

    change(event) {
        this.element.classList.remove('is-invalid');
    }
}
