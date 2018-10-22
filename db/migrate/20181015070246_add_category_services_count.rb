# frozen_string_literal: true

class AddCategoryServicesCount < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :services_count, :integer, default: 0
  end
end
