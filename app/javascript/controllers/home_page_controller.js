import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ["changeTab", "tab"];

    connect() {
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
}