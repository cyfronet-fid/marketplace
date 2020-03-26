import Choices from 'choices.js'

export default function initChoises(scope = document) {
  const elements = scope.querySelectorAll('[data-choice]');
  elements.forEach(function(element) {
    new Choices(element, {
      removeItems: true,
      placeholder: true,
      placeholderValue: '+ Add',
      removeItemButton: true,
    });
  });
}
