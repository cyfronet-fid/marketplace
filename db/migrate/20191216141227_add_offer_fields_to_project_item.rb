# frozen_string_literal: true

class AddOfferFieldsToProjectItem < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :name, :string
    add_column :project_items, :description, :text
    add_column :project_items, :offer_type, :string
    add_column :project_items, :webpage, :string
    add_column :project_items, :voucherable, :boolean, default: false, null: false

    execute(<<~SQL)
      UPDATE project_items
      SET
        offer_type = (SELECT offer.offer_type FROM offers offer WHERE offer.id = offer_id),
        name = (SELECT offer.name FROM offers offer WHERE offer.id = offer_id),
        description = (SELECT offer.description FROM offers offer WHERE offer.id = offer_id),
        webpage = (SELECT offer.webpage FROM offers offer WHERE offer.id = offer_id),
        voucherable = (SELECT offer.voucherable FROM offers offer WHERE offer.id = offer_id)
      SQL

    change_column :project_items, :name, :string, null: false
    change_column :project_items, :description, :text, null: false
    change_column :project_items, :offer_type, :string, null: false
  end

  def down
    remove_column :project_items, :name, :string
    remove_column :project_items, :description, :text
    remove_column :project_items, :offer_type, :string
  end
end
