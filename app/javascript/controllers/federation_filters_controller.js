import { Controller } from "@hotwired/stimulus";

// Controller name: federation-filters
// Attaches to the search form (#search-form). It:
// - Initializes Chosen on multi-selects if available
// - Updates hidden inputs for selected federation nodes
// - Auto-submits the form when node checkboxes change
// - Provides clearFilters action to reset filters but keep the search query
export default class extends Controller {
  static targets = ["form"];
  connect() {
    // Cache frequently used elements
    this.form = this.element; // assuming data-controller is set on the form element

    // Initialize chosen for multi-selects if present
    try {
      if (window.$ && typeof window.$.fn !== "undefined" && typeof window.$.fn.chosen !== "undefined") {
        window.$("select[multiple]", this.form).chosen({
          placeholder_text_multiple: "Select options...",
          no_results_text: "No results found",
        });
      }
    } catch (e) {
      // Fail silently if chosen or jQuery is unavailable
      // console.debug("Chosen init skipped:", e);
    }

    // Bind change handlers for node checkboxes
    this._bindNodeCheckboxes();

    // Ensure hidden nodes inputs reflect current state on connect
    this.updateHiddenNodes();
  }

  clearFilters(event) {
    if (event) event.preventDefault();
    const url = new URL(window.location.href);
    const params = new URLSearchParams(url.search);

    const q = params.get("q");

    let newQuery = "";
    if (q !== null) {
      newQuery = "?q=" + encodeURIComponent(q);
    }

    window.location.href = window.location.pathname + newQuery + window.location.hash;
  }

  updateHiddenNodes() {
    const hiddenContainer = this.form.querySelector("#hidden-nodes-container");
    if (!hiddenContainer) return;

    // Remove existing hidden inputs
    hiddenContainer.querySelectorAll(".hidden-node-input").forEach((el) => el.remove());

    // Add hidden inputs for checked node checkboxes
    this.form.querySelectorAll(".node-checkbox:checked").forEach((checkbox) => {
      const nodeName = checkbox.getAttribute("data-node-name") || checkbox.dataset.nodeName || checkbox.value;
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "nodes[]";
      input.value = nodeName;
      input.className = "hidden-node-input";
      hiddenContainer.appendChild(input);
    });
  }

  _bindNodeCheckboxes() {
    // Remove any existing listeners by cloning (ensures idempotency if Turbo reconnects)
    this.form.querySelectorAll(".node-checkbox").forEach((checkbox) => {
      // Use addEventListener with bound handler stored on the element to support cleanup if needed
      const handler = () => {
        this.updateHiddenNodes();
        // Short delay to allow visual feedback
        setTimeout(() => {
          this.form.submit();
        }, 100);
      };

      // To avoid multiple bindings across Turbo visits, remove previous if stored
      if (checkbox._federationFiltersHandler) {
        checkbox.removeEventListener("change", checkbox._federationFiltersHandler);
      }
      checkbox._federationFiltersHandler = handler;
      checkbox.addEventListener("change", handler);
    });
  }
}
