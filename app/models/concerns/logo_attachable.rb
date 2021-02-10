# frozen_string_literal: true

module LogoAttachable
  def logo_variable
    if logo.present? && !logo.variable?
      errors.add(:logo, "^The logo format you're trying to attach is not supported.
                          Supported formats: png, gif, jpg, jpeg,
                          pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon.")
    end
  end
end
