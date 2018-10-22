# frozen_string_literal: true

class AddConnectedUrlToServices < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :connected_url, :text, null: true
  end
end
