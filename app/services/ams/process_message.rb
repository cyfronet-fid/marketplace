# frozen_string_literal: true

module Ams
  class ProcessMessage
    include Callable
    include Importable

    JOBS_MAP = {
      "catalogue" => {
        create_or_update_job: Catalogue::PcCreateOrUpdateJob
      },
      "datasource" => {
        create_or_update_job: Datasource::PcCreateOrUpdateJob,
        delete_job: Datasource::DeleteJob
      },
      "deployable_application" => {
        create_or_update_job: DeployableService::PcCreateOrUpdateJob,
        delete_job: DeployableService::DeleteJob
      },
      "interoperability_record" => {
        create_or_update_job: Guideline::PcCreateOrUpdateJob,
        delete_job: Guideline::DeleteJob
      },
      "organisation" => {
        create_or_update_job: Provider::PcCreateOrUpdateJob,
        delete_job: Provider::DeleteJob
      },
      "service" => {
        create_or_update_job: Service::PcCreateOrUpdateJob,
        delete_job: Service::DeleteJob
      }
    }.freeze

    SUBSCRIPTION_PARTS_FORMAT = /\A(?:(?<prefix>[^-]+)-)?(?<resource>[^-]+)-(?<action>[^-]+)\z/

    def initialize(subscription_name, message:)
      @subscription_name = subscription_name
      @message = message

      @action = subscription_parts[:action]
      @resource = subscription_parts[:resource]
    end

    def call
      case action
      when "create", "update"
        create_or_update_later
      when "delete"
        delete_later
      end
    end

    private

    attr_reader :subscription_name, :message, :action, :resource

    def subscription_parts
      @subscription_parts ||= subscription_name.match(SUBSCRIPTION_PARTS_FORMAT).named_captures.symbolize_keys
    end

    def create_or_update_later
      job = JOBS_MAP.dig(resource, :create_or_update_job)
      return job.perform_later(message.dig("data", resource_key), status, modified_at) if job

      Ams::Logger.warn("Unsupported '#{action}' for resource '#{resource}'")
    end

    def delete_later
      job = JOBS_MAP.dig(resource, :delete_job)
      return job.perform_later(message.dig("data", "id")) if job

      Ams::Logger.warn("Unsupported '#{action}' for resource '#{resource}'")
    end

    def modified_at
      m = message.dig("data", "metadata", "modifiedAt")
      m ? Time.zone.at(Rational(m.to_i, 1000)) : Time.zone.now
    end

    def status
      object_status(
        message.dig("data", "active"),
        message.dig("data", "suspended")
      )
    end

    def resource_key
      resource.camelize(:lower)
    end
  end
end
