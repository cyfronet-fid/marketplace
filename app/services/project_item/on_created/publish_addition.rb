# frozen_string_literal: true

class ProjectItem::OnCreated::PublishAddition < ApplicationService
  def initialize(project, added_project_items)
    super()
    @project = project
    @added_project_items = added_project_items
  end

  def call
    @added_project_items
      .map(&:service)
      .uniq
      .filter_map { |s| jms_message(s) if publish_to_jms?(s) }
      .each { |msg| Jms::PublishJob.perform_later(msg) }
  end

  private

  def publish_to_jms?(service)
    service.upstream&.eosc_registry?
  end

  def jms_message(service)
    {
      message_type: "project.resource_addition",
      timestamp: Time.now.utc.iso8601,
      project_digest: project_digest,
      resource: service.pid
    }
  end

  def project_digest
    Digest::MD5.hexdigest(@project.id.to_s)
  end
end
