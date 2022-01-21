import Choices from "choices.js";

export default function initChoices(scope = document) {
  // The "=true" portion ensures that the function will apply only to previously unhandled elements,
  // because the Choices lib will change the "data-choice" value from "true" to "active" after application.
  // This makes this function idempotent.
  const elements = scope.querySelectorAll('[data-choice="true"]');

  elements.forEach(function (element) {
    new Choices(element, {
      removeItems: true,
      allowHTML: true,
      duplicateItemsAllowed: false,
      placeholder: true,
      placeholderValue: "+ start typing to add",
      removeItemButton: true,
    });
  });
}
