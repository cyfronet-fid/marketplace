# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Specify serializers for custom objects.
Rails.application.reloader.to_prepare do
  active_job = Rails.application.config.active_job

  # Active job removes the key sometimes, which manifests when reloading the application.
  # So we have to code around it.
  active_job.custom_serializers ||= []
  active_job.custom_serializers << ReportsSerializer if active_job.custom_serializers.exclude?(ReportsSerializer)
end
