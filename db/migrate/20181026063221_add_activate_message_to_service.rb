# frozen_string_literal: true

class AddActivateMessageToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :activate_message, :text
  end
end
