# frozen_string_literal: true

module LogoAttachable
  def logo_variable
    if logo.present? && !logo.variable?
      errors.add(:logo, "^Sorry, but the logo format you were trying to attach is not supported
                          in the Marketplace. Please attach the logo in png, gif, jpg, jpeg,
                          pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon format.")
    end
  end
end
