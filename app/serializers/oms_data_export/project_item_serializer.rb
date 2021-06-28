# frozen_string_literal: true

class OMSDataExport::ProjectItemSerializer < ActiveModel::Serializer
  attribute :id, key: :mp_id
  attribute :issue_id, key: :jira_id
  attribute :project_id
end
