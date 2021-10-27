# frozen_string_literal: true

class MigrateServicesToPublishedStatus < ActiveRecord::Migration[6.0]
  def change
    execute(
      <<~SQL.squish
        UPDATE services
        SET status = 'published'
        WHERE status = 'unverified';
      SQL
    )
  end
end
