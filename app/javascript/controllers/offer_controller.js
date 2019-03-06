import {Controller} from 'stimulus'

export default class extends Controller {
  static targets = ["parameters"];

  connect() {}

  initialize() {}

  addField(event) {
    event.preventDefault();
    var child = document.createElement("textarea")

    child.setAttribute("class", "form-control json")
    child.setAttribute("name", "offer[parameters_as_string][]")
    child.id = "offer_parameters_as_string_"+(this.parametersTarget.children.length-1)
    child.setAttribute("type", "text")
    child.setAttribute("rows", 10)

    this.parametersTarget.appendChild(child)
  }
}
