# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :user

  has_many :project_items, dependent: :destroy

  validates :name,
            presence: true,
            uniqueness: { scope: :user, message: "Project name need to be unique" }
end
