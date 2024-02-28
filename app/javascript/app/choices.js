import Choices from "choices.js";

export default function initChoices(scope = document) {
  // The "=true" portion ensures that the function will apply only to previously unhandled elements,
  // because the Choices lib will change the "data-choice" value from "true" to "active" after application.
  // This makes this function idempotent.
  const elements = Array.from(scope.querySelectorAll('[data-choice="true"]:not([data-render=false])'));
  console.log("--------------------");
  console.log(elements);
  console.log("--------------------");
  elements.forEach((e) => {
    console.log(!e.hasAttribute("data-render"));
  });

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
