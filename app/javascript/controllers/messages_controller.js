import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["scrollbar"]

  connect(){
  }

  initialize(){
    this._set_scrollbar_to_bottom()
  }

  _set_scrollbar_to_bottom(){
    console.log(this.scrollbarTarget)
    this.scrollbarTarget.scrollTo(0, this.scrollbarTarget.scrollHeight)
  }
}
