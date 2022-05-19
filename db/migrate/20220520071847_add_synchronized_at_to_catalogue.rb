# frozen_string_literal: true

class AddSynchronizedAtToCatalogue < ActiveRecord::Migration[6.1]
  def change
    add_column :catalogues, :synchronized_at, :datetime
  end
end
