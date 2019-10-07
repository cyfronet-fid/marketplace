import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["parent"];

    hidePrompt(event) {
        event.preventDefault();
        const buttons = document.getElementsByClassName("moveButton")
        Array.prototype.forEach.call(buttons, function (btn) {
            btn.setAttribute("disabled", true);
        });
        document.getElementById("action-frame").innerHTML = "";
    }
}
