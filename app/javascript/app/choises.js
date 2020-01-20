import Choices from 'choices.js'

export default function initChoises() {
  new Choices('[data-choice]', {
    removeItems: true,
    placeholder: true,
    placeholderValue: '+ Add',
    removeItemButton: true,
  });
}
