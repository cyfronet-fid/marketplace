# frozen_string_literal: true

module Mp
  # Which deployment node (marketplace / pl-marketplace / whitelabel-marketplace)
  # this process is running as, per ADR-0001. Backed by config/variants.yml and
  # the MARKETPLACE_VARIANT env var. Use the predicates below to key off it
  # instead of comparing `current` directly.
  module Variant
    def self.current
      Mp::Application.config.variants[:current].to_sym
    end

    def self.marketplace?
      current == :marketplace
    end

    def self.pl?
      current == :pl
    end

    def self.whitelabel?
      current == :whitelabel
    end
  end
end
