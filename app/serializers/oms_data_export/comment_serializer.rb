# frozen_string_literal: true

class OMSDataExport::CommentSerializer < ActiveModel::Serializer
  attribute :id, key: :mp_id
  # attribute :issue_id, key: :jira_id # TODO what is jira_id in this case?
  attribute :project_item_id
  attribute :project_id

  def project_item_id
    object.messageable_type == "ProjectItem" ? object.messageable_id : nil
  end

  def project_id
    object.messageable_type == "Project" ? object.messageable_id : nil
  end
end
