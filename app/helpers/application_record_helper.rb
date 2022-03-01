# frozen_string_literal: true

module ApplicationRecordHelper
  def self.required_attr?(obj, attribute)
    target = obj.instance_of?(Class) ? obj : obj.class
    target.validators_on(attribute).map(&:class).include?(ActiveModel::Validations::PresenceValidator)
  end
end
