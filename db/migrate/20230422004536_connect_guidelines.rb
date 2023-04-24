# frozen_string_literal: true
class ConnectGuidelines < ActiveRecord::Migration[6.1]
  def change
    create_join_table :services, :guidelines, table_name: :service_guidelines do |t|
      t.index :guideline_id
      t.index :service_id
    end

    add_index :service_guidelines, %i[guideline_id service_id], unique: true
  end
end
