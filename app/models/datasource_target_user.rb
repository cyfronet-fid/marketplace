# frozen_string_literal: true

class DatasourceTargetUser < ApplicationRecord
  belongs_to :datasource
  belongs_to :target_user

  validates :datasource, presence: true
  validates :target_user, presence: true, uniqueness: { scope: :datasource_id }
end
