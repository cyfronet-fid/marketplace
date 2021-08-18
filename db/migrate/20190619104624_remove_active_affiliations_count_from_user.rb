# frozen_string_literal: true

class RemoveActiveAffiliationsCountFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :active_affiliations_count
  end
end
