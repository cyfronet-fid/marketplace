import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["select"]

  connect(){}

  initialize(){
    let url = new URL(window.location.href)
    if(url.searchParams.has("q") && !url.searchParams.has("sort"))
      this.selectTarget.value = "_score"
  }
}
