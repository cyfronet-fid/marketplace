# frozen_string_literal: true

class AddWelcomePopupToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :show_welcome_popup, :boolean, default: false, null: false
  end
end
