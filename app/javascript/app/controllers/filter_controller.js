import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["form"];

  pageShow() {
    this.checkActiveMulticheckboxFilters();
    this.checkActiveSelectFilters();
  }

  toggle(event) {
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed};expires=${this.expireAtString()}`;
  }

  reload(event) {
    let form = this.formTarget;
    for (const element of form) {
      if (
        !element.dataset.indelible &&
        ((element.tagName === "INPUT" && !element.checked) || (element.tagName === "SELECT" && element.value == ""))
      ) {
        element.disabled = true;
      }
    }
    form.submit();
    document.getElementsByClassName("spinner-background")[0].style.display = "flex";
  }

  checkActiveMulticheckboxFilters() {
    let checkboxes = this.formTarget.getElementsByTagName("input");
    const urlSearchParams = new URLSearchParams(window.location.search);

    for (const element of checkboxes) {
      const params = urlSearchParams.getAll(element.name);
      if (!(params === element.value || params.includes(element.value)) && element.type == "checkbox") {
        element.checked = false;
      } else if (element.type == "checkbox") {
        element.checked = true;
      }
    }
  }

  checkActiveSelectFilters() {
    let selectable = this.formTarget.getElementsByTagName("select");

    const urlSearchParams = new URLSearchParams(window.location.search);

    for (const element of selectable) {
      const param = urlSearchParams.get(element.name);
      if (param === element.value) {
        element.value = param;
      } else {
        element.value = "";
      }
    }
  }

  expireAtString() {
    // 30 minutes
    return new Date(new Date().getTime() + 1000 * 1800).toGMTString();
  }
}
