# frozen_string_literal: true

class RenameHostingLegalEntity < ActiveRecord::Migration[6.1]
  def change
    rename_column :providers, :hosting_legal_entity, :hosting_legal_entity_string
  end
end
