# frozen_string_literal: true

class AddScopeToCatalogue < ActiveRecord::Migration[6.1]
  def change
    add_column :catalogues, :scope, :text, default: ""
  end
end
