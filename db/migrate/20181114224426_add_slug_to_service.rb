# frozen_string_literal: true

class AddSlugToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :slug, :string, unique: true
  end
end
