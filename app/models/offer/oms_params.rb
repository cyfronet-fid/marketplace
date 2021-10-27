# frozen_string_literal: true

class Offer::OMSParams
  MODEL_NAME = ActiveModel::Name.new(self.class, nil, "oms_params")

  def model_name
    MODEL_NAME
  end

  def initialize(hash)
    @object = hash&.symbolize_keys || {}
  end

  def method_missing(method, *args, &block)
    if @object.key? method
      @object[method]
    elsif @object.respond_to? method
      @object.send(method, *args, &block)
    end
  end

  def respond_to_missing?(method)
    @object.key? method or @object.respond_to? method
  end
end
