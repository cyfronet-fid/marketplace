import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ['element', 'toggler'];
    alwaysShow = 5;
    show = false;
    extraElements = 0;

    initialize() {
        console.log('multicheckbox initialize');
    }

    connect() {
        console.log('multicheckbox connect');
        this.toggle();
    }

    toggle() {
        this.extraElements = this.elementTargets.length - this.alwaysShow;

        if (this.extraElements <= 0)
            return;

        console.log('multicheckbox toggle');
        this.show = !this.show;

        this.elementTargets.forEach((el, i) => {
            if(i >= this.alwaysShow && el.querySelector('input').checked) {
              --this.extraElements;
            }
            else if (i >= this.alwaysShow && !el.querySelector('input').checked) {
                if (this.show)
                    el.classList.add("d-none");
                else
                    el.classList.remove("d-none");
            }
        });

        if (this.show)
            this.togglerTarget.textContent = `Show ${this.extraElements} more`;
        else
            this.togglerTarget.textContent = 'Show less';

        if(this.extraElements <= 0)
            this.togglerTarget.classList.add('d-none');
    }
}
