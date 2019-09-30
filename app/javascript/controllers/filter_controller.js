import {Controller} from 'stimulus'

export default class extends Controller {
  toggle(event) {
    const target = event.currentTarget;
    const collapsed = !target.classList.contains("collapsed");

    document.cookie = `${target.id}=${collapsed}`;
  }
}
