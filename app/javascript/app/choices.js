import Choices from 'choices.js'

export default function initChoices(scope = document) {
  const elements = scope.querySelectorAll('[data-choice]');

  elements.forEach(function(element) {
    new Choices(element, {
      removeItems: true,
      placeholder: true,
      placeholderValue: '+ start typing to add',
      removeItemButton: true,
    });
  });
}
