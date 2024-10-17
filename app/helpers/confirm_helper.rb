# frozen_string_literal: true

module ConfirmHelper
  def fill(singular)
    singular ? "this" : "these"
  end
  def publish_message(type = "rovider", singular: true)
    type = type.pluralize unless singular
    "Publishing #{fill(singular)} #{type} will make it visible to the users. " + "Do you want to continue?"
  end

  def unpublish_message(type = "provider", singular: true)
    type = type.pluralize unless singular
    "Unpublishing #{fill(singular)} #{type} will make it not longer visible to the users. " + "Do you want to continue?"
  end

  def suspend_message(type = "provider", singular: true)
    type = type.pluralize unless singular
    "Suspending #{fill(singular)} #{type} will temporarily disable it. Do you want to continue?"
  end

  def delete_message(type = "provider", singular: false)
    type = type.pluralize unless singular
    "Deleting #{fill(singular)} #{type} is permanently and cannot be undone. Do you want to continue?"
  end
end
