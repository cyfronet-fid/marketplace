# frozen_string_literal: true

# Daily Views of a Service, Provider or Bundle, read back from Matomo by
# Statistics::SyncViews (ADR-0008 D9).
class CreateViewStatistics < ActiveRecord::Migration[7.2]
  def change
    # A row is a day's numbers as Matomo reports them; it has no life of its own to time.
    create_table :view_statistics do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      # The unique index below covers the lookups by viewable.
      t.references :viewable, polymorphic: true, null: false, index: false
      t.date :date, null: false
      t.integer :views, null: false, default: 0
      t.integer :visits, null: false, default: 0
    end

    add_index :view_statistics,
              %i[viewable_type viewable_id date],
              unique: true,
              name: "index_view_statistics_on_viewable_and_date"
  end
end
