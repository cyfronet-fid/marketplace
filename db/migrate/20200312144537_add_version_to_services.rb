# frozen_string_literal: true

class AddVersionToServices < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :version, :string
  end
end
