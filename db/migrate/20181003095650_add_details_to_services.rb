# frozen_string_literal: true

class AddDetailsToServices < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :places, :text, null: false
    add_column :services, :languages, :text, null: false
    add_column :services, :dedicated_for, :text, null: false
    add_column :services, :terms_of_use_url, :text, null: false
    add_column :services, :access_policies_url, :text, null: false
    add_column :services, :corporate_sla_url, :text, null: false
    add_column :services, :webpage_url, :text, null: false
    add_column :services, :manual_url, :text, null: false
    add_column :services, :helpdesk_url, :text, null: false
    add_column :services, :tutorial_url, :text, null: false
    add_column :services, :restrictions, :text, null: false
    add_column :services, :phase, :text, null: false
  end
end
