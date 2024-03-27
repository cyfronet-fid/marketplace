import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["changeTab", "tab", "scrollArrow"];

  connect() {
    document.addEventListener("scroll", this.onScroll());
  }

  initialize() {}

  changeTab(event) {
    event.preventDefault();
    let tabLink = event.target;
    let tab = document.getElementById(tabLink.dataset.tab);
    this.changeTabTargets.forEach((el) => {
      el.classList.remove("current");
    });
    this.tabTargets.forEach((el) => {
      el.classList.remove("current");
    });
    tabLink.classList.add("current");
    tab.classList.add("current");
  }

  onScroll(event) {
    let height = window.scrollY;
    const el = document.getElementsByClassName("home-anchor")[0];
    if (height > 600) {
      el.style.opacity = 1;
      (function fadeOut() {
        (el.style.opacity -= 0.1) > 0 ? setTimeout(fadeOut, 40) : el.classList.add("d-none");
      })();
      el.classList.remove("d-block");
    }
    if (height < 400 && this.isMobileDevice()) {
      el.classList.remove("d-none");
      (function fadeIn() {
        (el.style.opacity += 0.1) < 1 ? setTimeout(fadeIn, 40) : el.classList.add("d-block");
      })();
      el.style.opacity = 1;
    }
  }

  isMobileDevice() {
    return typeof window.orientation !== "undefined" || navigator.userAgent.indexOf("IEMobile") !== -1;
  }
}
