# frozen_string_literal: true

module LogoAttachable
  include ImageHelper

  def logo_variable
    errors.add(:logo, ImageHelper::PERMITTED_EXT_MESSAGE) if logo.present? && !logo.variable?
  end
end
