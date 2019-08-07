# frozen_string_literal: true

class RemoveUserRefFromProjectItems < ActiveRecord::Migration[5.2]
  def change
    remove_reference :project_items, :user, index: true
  end
end
