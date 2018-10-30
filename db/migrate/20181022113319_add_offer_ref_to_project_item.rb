# frozen_string_literal: true

class AddOfferRefToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_items, :offer, foreign_key: true, index: true
  end
end
