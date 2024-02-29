import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    const self = this;
    setTimeout(function () {
      const { scrollHeight, clientHeight, offsetHeight } = self.element;
      if (scrollHeight >= clientHeight) {
        self.element.scrollTop = scrollHeight - clientHeight;
      }
    }, 100);
  }
}
