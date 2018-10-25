# frozen_string_literal: true

class RemoveServiceRefFromProjectItem < ActiveRecord::Migration[5.2]
  def change
    remove_reference :project_items, :service, index: true, foreign: true
  end
end
