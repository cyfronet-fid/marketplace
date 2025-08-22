# frozen_string_literal: true

module ConfigLoaderHelper
  def load_config(default_config:)
    log "Loading configuration with file #{@config_file_path}..."
    config =
      (
        if @config_file_path && File.exist?(@config_file_path)
          HashWithIndifferentAccess.new(YAML.load_file(@config_file_path, aliases: true))
        else
          log "Configuration file not found, using default configuration"
          Mp::Application.config_for(default_config)
        end
      )
    environment = Rails.env || "development"
    result = config[environment] || config

    expanded_result = expand_environment_variables(result)
    validate_config!(expanded_result)
    expanded_result
  rescue StandardError => e
    @logger.error("Failed to load configuration: #{e.message}")
    raise
  end

  def expand_environment_variables(obj)
    case obj
    when Hash
      obj.transform_values { |v| expand_environment_variables(v) }
    when Array
      obj.map { |v| expand_environment_variables(v) }
    when String
      obj.gsub(/\$\{([^}]+)}/) { ENV[::Regexp.last_match(1)] || ::Regexp.last_match(0) }
    else
      obj
    end
  end

  def validate_config!(config)
    return if config.blank?

    begin
      JSON::Validator.validate!(config_schema, config)
      log "Configuration validation passed"
    rescue JSON::Schema::ValidationError => e
      error_msg = "Configuration validation failed: #{e.message}"
      @logger.error(error_msg)
      raise ArgumentError, error_msg
    rescue StandardError => e
      error_msg = "Unexpected error during configuration validation: #{e.message}"
      @logger.error(error_msg)
      raise
    end
  end
end
