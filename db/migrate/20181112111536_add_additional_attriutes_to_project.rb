# frozen_string_literal: true

class AddAdditionalAttriutesToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :reason_for_access, :text
    add_column :projects, :customer_typology, :string
  end
end
