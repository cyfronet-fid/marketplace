# frozen_string_literal: true

class RenameCorporateSlaInServices < ActiveRecord::Migration[5.2]
  def change
    rename_column :services, :corporate_sla_url, :sla_url
  end
end
