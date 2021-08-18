# frozen_string_literal: true

class AddActiveAffiliationsCount < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :active_affiliations_count, :integer, default: 0
  end
end
