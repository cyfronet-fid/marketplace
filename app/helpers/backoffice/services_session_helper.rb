# frozen_string_literal: true

module Backoffice::ServicesSessionHelper
  ATTR_FIELD_NAME = "attributes"
  LOGO_FIELD_NAME = "logo"

  def session_key
    "service-#{@service&.id || "new"}-preview"
  end

  def remove_temp_data!(save_logo: false)
    return unless session[session_key]
    save_logo ? session[session_key].delete(ATTR_FIELD_NAME) : session.delete(session_key)
  end

  def temp_attrs
    session[session_key][ATTR_FIELD_NAME] if temp_attrs?
  end

  def temp_attrs?
    session[session_key]&.key?(ATTR_FIELD_NAME)
  end

  def temp_logo
    session[session_key][LOGO_FIELD_NAME] if temp_logo?
  end

  def temp_logo?
    session[session_key]&.key?(LOGO_FIELD_NAME)
  end

  def store_attrs!(attrs)
    attrs = attrs.each_value { |value| value.reject!(&:blank?) if value.instance_of?(Array) }
    attrs = attrs.reject { |key, value| value.blank? if ApplicationRecordHelper.required_attr?(Service, key) }
    session[session_key] = { ATTR_FIELD_NAME => attrs }
    store_logo!(attrs)
  end

  def store_logo!(attrs)
    logo = ImageHelper.to_json(attrs.delete(:logo))
    session[session_key][LOGO_FIELD_NAME] = logo
  end
end
