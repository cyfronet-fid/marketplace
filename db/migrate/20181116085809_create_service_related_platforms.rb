# frozen_string_literal: true

class CreateServiceRelatedPlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :service_related_platforms do |t|
      t.belongs_to :service, foreign_key: true, index: true
      t.belongs_to :platform, foreign_key: true, index: true
    end
    add_index :service_related_platforms, %i[service_id platform_id], unique: true
  end
end
