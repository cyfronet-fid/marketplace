# frozen_string_literal: true

class ProjectItem::OnCreated::PublishCoexistence < ApplicationService
  def initialize(project)
    super()
    @project = project
  end

  def call
    coexisting_resources = resources
    Jms::PublishJob.perform_later(jms_message(coexisting_resources)) if coexisting_resources.present?
  end

  private

  def resources
    @project.project_items.map(&:service).uniq.filter_map { |s| s.pid if publish_to_jms?(s) }
  end

  def publish_to_jms?(service)
    service.upstream&.eosc_registry?
  end

  def jms_message(coexisting_resources)
    {
      message_type: "project.resource_coexistence",
      timestamp: Time.now.utc.iso8601,
      project_digest: project_digest,
      coexisting_resources: coexisting_resources.sort
    }
  end

  def project_digest
    Digest::MD5.hexdigest(@project.id.to_s)
  end
end
