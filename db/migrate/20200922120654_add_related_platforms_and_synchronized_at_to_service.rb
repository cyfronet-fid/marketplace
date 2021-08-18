# frozen_string_literal: true

class AddRelatedPlatformsAndSynchronizedAtToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :related_platforms, :string, array: true, default: []
    add_column :services, :synchronized_at, :datetime
  end
end
