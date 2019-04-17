import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ['collapsible', 'filter', 'options'];

    initialize() {
        console.log('Filters initialize');
    }

    connect() {
        console.log('Filters connect')
        this.showActiveFilters();
    }

    showActiveFilters() {
        this.filterTargets.forEach(el => {
            var checkOption = false;
            var query = el.querySelector('option[selected]');
            if (query && query.value) {
                checkOption = true;
            }
            if (!checkOption) {
                query = el.querySelector('input[checked]');
                if (query) {
                    checkOption = true;
                }
            }

            if (checkOption) {
                el.classList.add('show');
            }
            else {
                el.classList.remove('show');
            }
        });

    }
}