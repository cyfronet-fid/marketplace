# frozen_string_literal: true

locale_path = ENV["CUSTOMIZATION_PATH"].nil? ? "locale" : File.join(ENV["CUSTOMIZATION_PATH"], "locale")

FastGettext.add_text_domain "marketplace", path: locale_path, type: :po
FastGettext.default_available_locales = ["en"]
FastGettext.default_text_domain = "marketplace"
