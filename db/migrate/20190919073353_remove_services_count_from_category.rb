# frozen_string_literal: true

class RemoveServicesCountFromCategory < ActiveRecord::Migration[5.2]
  def change
    remove_column :categories, :services_count
  end
end
