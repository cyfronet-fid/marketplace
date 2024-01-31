# frozen_string_literal: true

class Offer::OMSParams
  MODEL_NAME = ActiveModel::Name.new(self.class, nil, "oms_params")

  def model_name
    MODEL_NAME
  end

  def initialize(hash)
    @object = hash&.symbolize_keys || {}
  end

  def respond_to_missing?(method, _include_private = false)
    @object.key?(method) || @object.respond_to?(method)
  end

  def method_missing(method, *, &)
    if @object.key?(method)
      @object[method]
    elsif @object.respond_to?(method)
      @object.send(method, *, &)
    end
  end

  def has_attribute?(attr)
    @object.key? attr
  end
end
