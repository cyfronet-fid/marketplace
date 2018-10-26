# frozen_string_literal: true

class CreateServiceAreas < ActiveRecord::Migration[5.2]
  def change
    create_table :service_areas do |t|
      t.belongs_to :service, index: true
      t.belongs_to :area, index: true

      t.timestamps
    end
  end
end
