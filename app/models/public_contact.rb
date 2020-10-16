# frozen_string_literal: true

class PublicContact < Contact
  def position_in_organisation
    "#{position} at #{organisation}" if position.present? && organisation.present?
  end

  def full_name
    "#{first_name} #{last_name}" if first_name.present? && last_name.present?
  end
end
