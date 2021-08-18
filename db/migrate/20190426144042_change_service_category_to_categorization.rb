# frozen_string_literal: true

class ChangeServiceCategoryToCategorization < ActiveRecord::Migration[5.2]
  def change
    rename_table :service_categories, :categorizations
  end
end
