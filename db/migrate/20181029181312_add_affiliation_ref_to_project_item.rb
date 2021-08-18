# frozen_string_literal: true

class AddAffiliationRefToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :project_items, :affiliation, foreign_key: true, index: true
  end
end
