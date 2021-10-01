import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["link"];

    initialize() {
        console.log("Preview connected")
        this.linkTargets.
            forEach(link => { link.href = "javascript:;" });
    }
}