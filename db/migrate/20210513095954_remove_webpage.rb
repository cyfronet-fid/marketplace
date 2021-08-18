# frozen_string_literal: true

class RemoveWebpage < ActiveRecord::Migration[6.0]
  def change
    exec_update "UPDATE services SET order_url = '' WHERE order_url IS NULL"
    change_column :services, :order_url, :string, null: false, default: ""

    exec_update "UPDATE offers SET order_url = '' WHERE order_url IS NULL"
    change_column :offers, :order_url, :string, null: false, default: ""

    exec_update "UPDATE project_items SET order_url = '' WHERE order_url IS NULL"
    change_column :project_items, :order_url, :string, null: false, default: ""

    exec_update "UPDATE offers SET webpage = '' WHERE webpage IS NULL"
    exec_update "UPDATE offers SET order_url = webpage WHERE order_url = ''"
    remove_column :offers, :webpage

    # Do the same for project_items, but use the values from project_item, not from current offer.
    # This is consistent with our wanting to have a partial "snapshot" of offer saved in the project_item.
    exec_update "UPDATE project_items SET webpage = '' WHERE webpage IS NULL"
    exec_update "UPDATE project_items SET order_url = webpage WHERE order_url = ''"
    remove_column :project_items, :webpage
  end
end
