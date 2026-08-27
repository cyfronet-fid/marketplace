# frozen_string_literal: true

module Ams
  class ProcessMessage
    include Callable

    SUBSCRIPTION_PARTS_FORMAT = /\A(?:(?<prefix>[^-]+)-)?(?<resource>[^-]+)-(?<action>[^-]+)\z/

    RESOURCE_HANDLERS_MAP = {
      "catalogue" => Ams::Handlers::Catalogue,
      "datasource" => Ams::Handlers::Datasource,
      "deployable_application" => Ams::Handlers::DeployableService,
      "interoperability_record" => Ams::Handlers::Guideline,
      "organisation" => Ams::Handlers::Provider,
      "service" => Ams::Handlers::Service
    }.freeze

    def initialize(subscription_name, message:)
      @subscription_name = subscription_name
      @message = message
    end

    def call
      handler_klass = RESOURCE_HANDLERS_MAP[subscription_parts[:resource]]

      unless handler_klass
        resource = subscription_parts[:resource]
        Ams::Logger.warn("No handler found for resource '#{resource}' (subscription: #{subscription_name})")
        return false
      end

      handler_klass.call(
        action: subscription_parts[:action],
        resource: subscription_parts[:resource],
        data: message["data"]
      )
    end

    private

    attr_reader :subscription_name, :message

    def subscription_parts
      @subscription_parts ||= subscription_name.match(SUBSCRIPTION_PARTS_FORMAT).named_captures.symbolize_keys
    end
  end
end
