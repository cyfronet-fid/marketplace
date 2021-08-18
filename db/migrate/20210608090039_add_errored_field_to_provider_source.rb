# frozen_string_literal: true

class AddErroredFieldToProviderSource < ActiveRecord::Migration[6.0]
  def change
    add_column :provider_sources, :errored, :jsonb
  end
end
