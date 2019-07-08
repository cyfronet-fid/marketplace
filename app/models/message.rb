# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :author,
             class_name: "User",
             optional: true

  validates :message, presence: true
  belongs_to :messageable, polymorphic: true

  def question?
    author == messageable.user
  end
end
