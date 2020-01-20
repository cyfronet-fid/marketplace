import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  toggle(event) {
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed};expires=${this.expireAtString()}`;
  }

  reload(event) {
    this.formTarget.submit();
    document.getElementsByClassName("spinner-background")[0].style.display = 'flex';
  }

  expireAtString() {
    // 30 minutes
    return new Date(new Date().getTime() + 1000*1800).toGMTString();
  }
}
