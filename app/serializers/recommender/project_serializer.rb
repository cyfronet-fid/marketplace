# frozen_string_literal: true

class Recommender::ProjectSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user_id
  attribute :services

  def services
    Service.joins(:project_items).where("project_items.project_id = ?", object.id).pluck(:id)
  end
end
