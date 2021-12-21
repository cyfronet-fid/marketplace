# frozen_string_literal: true

class AddSecurityContactEmailToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :security_contact_email, :string, null: false, default: ""
  end
end
