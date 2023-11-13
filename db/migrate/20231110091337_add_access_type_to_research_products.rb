# frozen_string_literal: true

class AddAccessTypeToResearchProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :research_products, :best_access_right, :string
  end
end
