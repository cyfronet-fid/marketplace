# frozen_string_literal: true

class OMSDataExport::ProjectSerializer < ActiveModel::Serializer
  attribute :id, key: :mp_id
  attribute :issue_id, key: :jira_id
end
