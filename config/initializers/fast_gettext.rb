# frozen_string_literal: true

# An empty CUSTOMIZATION_PATH (the marketplace image) is the same as no
# customization, as in config/application.rb.
locale_path = ENV["CUSTOMIZATION_PATH"].present? ? File.join(ENV["CUSTOMIZATION_PATH"], "locale") : "locale"

FastGettext.add_text_domain "marketplace", path: locale_path, type: :po
FastGettext.default_available_locales = ["en"]
FastGettext.default_text_domain = "marketplace"
