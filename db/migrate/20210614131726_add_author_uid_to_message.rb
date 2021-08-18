# frozen_string_literal: true

class AddAuthorUidToMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :author_uid, :string
  end
end
