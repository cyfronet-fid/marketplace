# frozen_string_literal: true

class AddDetailsToServices < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :places, :string, null: true
    add_column :services, :languages, :string, null: true
    add_column :services, :dedicated_for, :string, null: true
    add_column :services, :terms_of_use_url, :string, null: true
    add_column :services, :access_policies_url, :string, null: true
    add_column :services, :corporate_sla_url, :string, null: true
    add_column :services, :webpage_url, :string, null: true
    add_column :services, :manual_url, :string, null: true
    add_column :services, :helpdesk_url, :string, null: true
    add_column :services, :tutorial_url, :string, null: true
    add_column :services, :restrictions, :string, null: true
    add_column :services, :phase, :string, null: true
  end
end
