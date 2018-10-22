# frozen_string_literal: true

class AddProviderToService < ActiveRecord::Migration[5.2]
  def change
    add_reference :services, :provider
    add_foreign_key :services, :providers, column: :provider_id
  end
end
