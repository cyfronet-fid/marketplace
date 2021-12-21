# frozen_string_literal: true

class MigrateOffersToDeleted < ActiveRecord::Migration[6.0]
  def change
    execute(<<~SQL)
      UPDATE offers
      SET status = 'deleted'
      WHERE status = 'draft';
    SQL
  end
end
