import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ["showMore"];

  connect() {
  }

  initialize(){}

  showMore(event){
    const element = event.target
    event.preventDefault()
    this.showMoreTarget.parentElement.textContent = element.dataset.text
  }
}
