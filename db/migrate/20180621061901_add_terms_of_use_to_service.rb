# frozen_string_literal: true

class AddTermsOfUseToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :terms_of_use, :text
  end
end
