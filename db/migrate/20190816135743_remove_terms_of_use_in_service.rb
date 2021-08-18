# frozen_string_literal: true

class RemoveTermsOfUseInService < ActiveRecord::Migration[5.2]
  def change
    remove_column :services, :terms_of_use
  end
end
