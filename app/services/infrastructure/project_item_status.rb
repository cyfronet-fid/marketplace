# frozen_string_literal: true

# Project item status updates that follow the lifecycle of its deployed infrastructure.
module Infrastructure::ProjectItemStatus
  def self.ready!(project_item, deployment_url)
    project_item.update!(
      status: "Deployment ready at #{deployment_url}",
      status_type: :ready,
      deployment_link: deployment_url
    )
  end

  def self.rejected!(project_item, message)
    project_item.update!(status: message, status_type: :rejected, deployment_link: nil)
  end

  def self.closed!(project_item)
    project_item.update!(status: "Infrastructure has been destroyed", status_type: :closed)
  end
end
