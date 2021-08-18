# frozen_string_literal: true

class AddHelpdeskEmailToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :helpdesk_email, :string, default: ""
  end
end
