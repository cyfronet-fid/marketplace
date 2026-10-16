# frozen_string_literal: true

Rails.application.config.recaptcha_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("RECAPTCHA_ENABLED", true))
