# frozen_string_literal: true

module LogoAttachable
  include ImageHelper

  def logo_variable
    if logo.present? && !logo.variable?
      errors.add(:logo, ImageHelper.permitted_ext_message)
    end
  end
end
