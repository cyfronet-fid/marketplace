import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ['form']

  toggle(event) {
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed}`;
  }

  reload(event) {
    this.formTarget.submit();
  }
}
