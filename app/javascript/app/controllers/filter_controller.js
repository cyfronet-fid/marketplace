import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  toggle(event) {
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed};expires=${this.expireAtString()}`;
  }

  reload(event) {
    let form = this.formTarget;
    for (const element of form) {
      if ((element.tagName === "INPUT" && !element.checked) || (element.tagName === "SELECT" && element.value == "")) {
        element.disabled = true;
      }
    }
    form.submit();
    document.getElementsByClassName("spinner-background")[0].style.display = 'flex';
  }

  expireAtString() {
    // 30 minutes
    return new Date(new Date().getTime() + 1000*1800).toGMTString();
  }
}
