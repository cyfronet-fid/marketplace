import {Controller} from 'stimulus'

export default class extends Controller {
    static targets = ["changeTab", "tab", "scrollArrow"];

    connect() {
        document.addEventListener("scroll", this.onScroll());
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
        let height = window.scrollY;
        if (height > 600) {
            const el = document.getElementsByClassName('home-anchor')[0].style;
            el.opacity = 1;
            (function fade(){(el.opacity-= .1)<0?el.display="none":setTimeout(fade,60)})();

        }

    }

    $(".home-anchor").hide();
    $(window).scroll(function() {
        if ($(window).scrollTop() > 100) {
            $(".home-anchor").fadeIn("slow");
        }
        else {
            $(".home-anchor").fadeOut("fast");
        }
    });
}