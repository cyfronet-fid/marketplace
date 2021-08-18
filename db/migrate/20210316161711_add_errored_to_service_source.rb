# frozen_string_literal: true

class AddErroredToServiceSource < ActiveRecord::Migration[6.0]
  def change
    add_column :service_sources, :errored, :jsonb
  end
end
