# frozen_string_literal: true

module LogoAttachable
  include ImageHelper

  def logo_variable
    errors.add(:logo, ImageHelper.permitted_ext_message) if logo.present? && !logo.variable?
  end
end
