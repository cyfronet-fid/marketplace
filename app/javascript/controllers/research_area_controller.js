import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["parent"];

    hidePrompt(event) {
        event.preventDefault();
        const button = document.getElementById("submit");
        const label = button.getAttribute("label");
        button.setAttribute("value", label);
        const frame = document.getElementById("action-frame");
        if(frame) {
            frame.remove();
        }
    }
}
