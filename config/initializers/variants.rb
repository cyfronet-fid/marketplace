# frozen_string_literal: true

Rails.application.configure do
  if Rails.env.production? && ENV["MARKETPLACE_VARIANT"].blank?
    raise "MARKETPLACE_VARIANT must be set in production (one of #{config_for(:variants)[:available].inspect})"
  end

  config.variants = config_for(:variants)

  unless config.variants[:available].include?(config.variants[:current])
    raise "Unknown MARKETPLACE_VARIANT #{config.variants[:current].inspect}, " \
          "expected one of #{config.variants[:available].inspect}"
  end
end
