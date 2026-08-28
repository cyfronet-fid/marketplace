# frozen_string_literal: true

Rails.application.configure do
  config.variants = config_for(:variants)

  unless config.variants[:available].include?(config.variants[:current])
    raise "Unknown MARKETPLACE_VARIANT #{config.variants[:current].inspect}, " \
          "expected one of #{config.variants[:available].inspect}"
  end
end
