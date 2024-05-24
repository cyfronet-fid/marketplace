# frozen_string_literal: true

class AddTitleTypeToTitle < ActiveRecord::Migration[6.1]
  def change
    add_column :titles, :title_type, :string
  end
end
