import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  pageShow() {
    this.checkActiveMulticheckboxFilters();
    this.checkActiveSelectFilters();
  }

  toggle(event) {
    event.preventDefault();
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed};expires=${this.expireAtString()}`;
  }

  reload(event) {
    event.preventDefault();
    this.toggleParent(event);
    this.toggleChildren(event);
    let form = this.formTarget;
    for (const element of form) {
      if (
        !element.dataset.indelible &&
        ((element.tagName === "INPUT" && !element.checked) || (element.tagName === "SELECT" && element.value == ""))
      ) {
        element.disabled = true;
      }
    }
    document.getElementsByClassName("spinner-background")[0].style.display = "flex";
    form.submit();
  }

  toggleChildren(event) {
    const parent = event.target;
    const state = parent.checked;
    const childSelector = `[type='checkbox'][name='${parent.name}'][data-parent='${parent.value}']:enabled`;
    Array.from(document.querySelectorAll(childSelector)).forEach((child) => (child.checked = state));
  }

  toggleParent(event) {
    const element = event.target;
    const childSelector = `[type='checkbox'][name='${element.name}'][data-parent='${element.dataset.parent}']:enabled`;
    const otherChildren =
      Array.from(document.querySelectorAll(childSelector)).filter((value) => value !== element) || [];

    const state = element.checked;

    const anyChildHasDifferentState =
      otherChildren.length === 0 ? false : otherChildren.some((e) => e.checked !== state);
    const parent = document.querySelector(
      `[type='checkbox'][name='${element.name}'][value='${element.dataset.parent}']`,
    );

    if (!parent) {
      return;
    }
    if (anyChildHasDifferentState) {
      parent.checked = false;
      parent.indeterminate = true;
      parent.classList.add("indeterminate");
      return;
    }
    parent.classList.remove("indeterminate");
    parent.checked = state;
  }

  checkActiveMulticheckboxFilters() {
    let checkboxes = this.formTarget.getElementsByTagName("input");
    const urlSearchParams = new URLSearchParams(window.location.search);

    for (const element of checkboxes) {
      const params = urlSearchParams.getAll(element.name);
      if (params === element.value || (params.includes(element.value) && element.type == "checkbox")) {
        element.checked = true;
      } else if (element.type == "checkbox") {
        element.checked = false;
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
