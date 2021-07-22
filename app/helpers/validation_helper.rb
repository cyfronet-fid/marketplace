# frozen_string_literal: true

module ValidationHelper
  def validate_uuid_format(uuid)
    uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    uuid_regex.match?(uuid.to_s.downcase)
  end
end
