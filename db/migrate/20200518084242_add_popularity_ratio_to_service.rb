# frozen_string_literal: true

class AddPopularityRatioToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :popularity_ratio, :float
  end
end
