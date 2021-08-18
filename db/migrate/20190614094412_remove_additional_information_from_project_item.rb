# frozen_string_literal: true

class RemoveAdditionalInformationFromProjectItem < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_items, :additional_information, :text
  end
end
