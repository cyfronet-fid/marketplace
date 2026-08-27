# frozen_string_literal: true

class Ams::Handlers::Base
  include Callable
  include Importable

  ALLOWED_ACTIONS = %w[create update delete].freeze

  def initialize(action:, resource:, data:)
    @action = action
    @resource = resource
    @data = data
  end

  def call
    if ALLOWED_ACTIONS.exclude?(action)
      Ams::Logger.warn("Skipping message for resource '#{resource}': disallowed action '#{action}'")
      return
    end

    if data["id"].blank?
      Ams::Logger.warn("Skipping #{action} message for resource '#{resource}': missing id")
      return
    end

    case action
    when "delete"
      delete(data["id"])
    when "create", "update"
      create_or_update(data[resource_key])
    end
  end

  protected

  attr_reader :action, :resource, :data

  def delete(_id)
    raise NotImplementedError
  end

  def create_or_update(_payload)
    raise NotImplementedError
  end

  def modified_at
    m = data.dig("metadata", "modifiedAt")
    m ? Time.zone.at(m.to_i / 1000) : Time.zone.now
  end

  def status
    object_status(data["active"], data["suspended"])
  end

  def resource_key
    resource.camelize(:lower)
  end
end
