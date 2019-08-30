import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ["changeTab", "tab", "scrollArrow"];

    connect() {
        this.onScrollRunning = true
    }

    initialize(){}

    changeTab(event){
        event.preventDefault();
        let tabLink = event.target;
        let tab = document.getElementById(tabLink.dataset.tab);
        this.changeTabTargets.forEach((el) => {
            el.classList.remove('current');
        });
        this.tabTargets.forEach((el) => {
            el.classList.remove('current');
        });
        tabLink.classList.add('current');
        tab.classList.add('current');
    }

    onScroll(event) {
        if (!this.onScrollRunning) {
            this.onScrollRunning = true;
        }

        let height = window.scrollY;
        if (height > 600) {
            const el = document.getElementsByClassName('.home-anchor').style;
            el.opacity = 1;
            (function fade(){(el.opacity-= .1)<0?s.display="none":setTimeout(fade,40)})();

        }

    }
}