# frozen_string_literal: true

module Favoritable
  extend ActiveSupport::Concern

  included do
    # Polymorphic favourites relation
    has_many :user_favourites, as: :favoritable, dependent: :destroy
    # Use a non-generic name to avoid conflicts with existing associations like `has_many :users`
    has_many :favourited_by_users, through: :user_favourites, source: :user
  end
end
